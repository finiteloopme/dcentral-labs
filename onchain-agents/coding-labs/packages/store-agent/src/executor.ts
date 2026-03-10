import { v4 as uuidv4 } from 'uuid';
import type {
  Task,
  TaskArtifactUpdateEvent,
  TaskStatusUpdateEvent,
} from '@a2a-js/sdk';
import type {
  AgentExecutor,
  RequestContext,
  ExecutionEventBus,
} from '@a2a-js/sdk/server';
import type { WalletContext } from '@coding-labs/shared';
import {
  skillHandlers,
  detectSkill,
  extractTextFromMessage,
} from './skills/index.js';

function extractWalletContext(
  metadata?: Record<string, unknown>
): WalletContext | undefined {
  if (!metadata?.wallet) return undefined;
  const wallet = metadata.wallet as Record<string, unknown>;
  if (
    typeof wallet.address === 'string' &&
    typeof wallet.chainId === 'number' &&
    typeof wallet.connected === 'boolean'
  ) {
    return {
      address: wallet.address as `0x${string}`,
      chainId: wallet.chainId,
      connected: wallet.connected,
    };
  }
  return undefined;
}

export class StoreAgentExecutor implements AgentExecutor {
  private cancelledTasks = new Set<string>();

  public cancelTask = async (
    taskId: string,
    _eventBus: ExecutionEventBus
  ): Promise<void> => {
    console.log(`[StoreAgent] Cancellation requested for task: ${taskId}`);
    this.cancelledTasks.add(taskId);
  };

  async execute(
    requestContext: RequestContext,
    eventBus: ExecutionEventBus
  ): Promise<void> {
    const { userMessage, task: existingTask } = requestContext;
    const taskId = existingTask?.id || uuidv4();
    const contextId =
      userMessage.contextId || existingTask?.contextId || uuidv4();

    console.log(
      `[StoreAgent] Processing message ${userMessage.messageId} for task ${taskId}`
    );

    if (!existingTask) {
      const initialTask: Task = {
        kind: 'task',
        id: taskId,
        contextId: contextId,
        status: {
          state: 'submitted',
          timestamp: new Date().toISOString(),
        },
        history: [userMessage],
        metadata: userMessage.metadata,
        artifacts: [],
      };
      eventBus.publish(initialTask);
    }

    const userText = extractTextFromMessage(userMessage);
    const skillId = detectSkill(userText);
    const walletContext = extractWalletContext(
      userMessage.metadata as Record<string, unknown> | undefined
    );

    console.log(
      `[StoreAgent] Detected skill: ${skillId}, wallet: ${walletContext?.address || 'not connected'}`
    );

    const workingUpdate: TaskStatusUpdateEvent = {
      kind: 'status-update',
      taskId: taskId,
      contextId: contextId,
      status: {
        state: 'working',
        message: {
          kind: 'message',
          role: 'agent',
          messageId: uuidv4(),
          parts: [{ kind: 'text', text: `Using skill: ${skillId}...` }],
          taskId: taskId,
          contextId: contextId,
        },
        timestamp: new Date().toISOString(),
      },
      final: false,
    };
    eventBus.publish(workingUpdate);

    const handler = skillHandlers[skillId];
    if (!handler) {
      const errorUpdate: TaskStatusUpdateEvent = {
        kind: 'status-update',
        taskId: taskId,
        contextId: contextId,
        status: {
          state: 'failed',
          message: {
            kind: 'message',
            role: 'agent',
            messageId: uuidv4(),
            parts: [{ kind: 'text', text: `Skill '${skillId}' is not yet implemented.` }],
            taskId: taskId,
            contextId: contextId,
          },
          timestamp: new Date().toISOString(),
        },
        final: true,
      };
      eventBus.publish(errorUpdate);
      eventBus.finished();
      return;
    }

    try {
      const artifacts: string[] = [];

      for await (const event of handler(userMessage, walletContext)) {
        if (this.cancelledTasks.has(taskId)) {
          console.log(`[StoreAgent] Task ${taskId} cancelled`);
          this.cancelledTasks.delete(taskId);
          const cancelledUpdate: TaskStatusUpdateEvent = {
            kind: 'status-update',
            taskId: taskId,
            contextId: contextId,
            status: { state: 'canceled', timestamp: new Date().toISOString() },
            final: true,
          };
          eventBus.publish(cancelledUpdate);
          eventBus.finished();
          return;
        }

        switch (event.type) {
          case 'status': {
            const statusUpdate: TaskStatusUpdateEvent = {
              kind: 'status-update',
              taskId, contextId,
              status: {
                state: 'working',
                message: {
                  kind: 'message', role: 'agent', messageId: uuidv4(),
                  parts: [{ kind: 'text', text: event.message }],
                  taskId, contextId,
                },
                timestamp: new Date().toISOString(),
              },
              final: false,
            };
            eventBus.publish(statusUpdate);
            break;
          }
          case 'artifact': {
            artifacts.push(event.name);
            const artifactUpdate: TaskArtifactUpdateEvent = {
              kind: 'artifact-update',
              taskId, contextId,
              artifact: {
                artifactId: event.name,
                name: event.name,
                parts: [{ kind: 'text', text: event.content }],
              },
              append: false,
              lastChunk: true,
            };
            eventBus.publish(artifactUpdate);
            break;
          }
          case 'error': {
            const errorUpdate: TaskStatusUpdateEvent = {
              kind: 'status-update',
              taskId, contextId,
              status: {
                state: 'failed',
                message: {
                  kind: 'message', role: 'agent', messageId: uuidv4(),
                  parts: [{ kind: 'text', text: event.message }],
                  taskId, contextId,
                },
                timestamp: new Date().toISOString(),
              },
              final: true,
            };
            eventBus.publish(errorUpdate);
            eventBus.finished();
            return;
          }
          case 'result':
            break;
        }
      }

      const completionMessage =
        artifacts.length > 0
          ? `Generated: ${artifacts.join(', ')}`
          : 'Task completed successfully.';

      const finalUpdate: TaskStatusUpdateEvent = {
        kind: 'status-update',
        taskId, contextId,
        status: {
          state: 'completed',
          message: {
            kind: 'message', role: 'agent', messageId: uuidv4(),
            parts: [{ kind: 'text', text: completionMessage }],
            taskId, contextId,
          },
          timestamp: new Date().toISOString(),
        },
        final: true,
      };
      eventBus.publish(finalUpdate);
      eventBus.finished();

      console.log(`[StoreAgent] Task ${taskId} completed successfully`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error(`[StoreAgent] Task ${taskId} failed:`, error);

      const errorUpdate: TaskStatusUpdateEvent = {
        kind: 'status-update',
        taskId, contextId,
        status: {
          state: 'failed',
          message: {
            kind: 'message', role: 'agent', messageId: uuidv4(),
            parts: [{ kind: 'text', text: `Agent error: ${errorMessage}` }],
            taskId, contextId,
          },
          timestamp: new Date().toISOString(),
        },
        final: true,
      };
      eventBus.publish(errorUpdate);
      eventBus.finished();
    }
  }
}
