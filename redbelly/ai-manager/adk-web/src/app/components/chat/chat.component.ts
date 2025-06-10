/**
 * @license
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {HttpErrorResponse} from '@angular/common/http';
import {AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, inject, OnDestroy, OnInit, signal, ViewChild, WritableSignal} from '@angular/core';
import {FormControl} from '@angular/forms';
import {MatDialog, MatDialogModule} from '@angular/material/dialog';
import {MatPaginatorIntl} from '@angular/material/paginator';
import {MatDrawer} from '@angular/material/sidenav';
import {MatSnackBar} from '@angular/material/snack-bar';
import {DomSanitizer, SafeHtml} from '@angular/platform-browser';
import {ActivatedRoute, NavigationEnd, Router} from '@angular/router';
import {instance} from '@viz-js/viz';
import {BehaviorSubject, catchError, combineLatest, distinctUntilChanged, filter, map, Observable, of, shareReplay, switchMap, take, tap} from 'rxjs';

import {URLUtil} from '../../../utils/url-util';
import {AgentRunRequest} from '../../core/models/AgentRunRequest';
import {Session} from '../../core/models/Session';
import {AgentService} from '../../core/services/agent.service';
import {ArtifactService} from '../../core/services/artifact.service';
import {AudioService} from '../../core/services/audio.service';
import {DownloadService} from '../../core/services/download.service';
import {EvalService} from '../../core/services/eval.service';
import {EventService} from '../../core/services/event.service';
import {FeatureFlagService} from '../../core/services/feature-flag.service';
import {SessionService} from '../../core/services/session.service';
import {VideoService} from '../../core/services/video.service';
import {WebSocketService} from '../../core/services/websocket.service';
import {ResizableDrawerDirective} from '../../directives/resizable-drawer.directive';
import {getMediaTypeFromMimetype, MediaType, openBase64InNewTab} from '../artifact-tab/artifact-tab.component';
import {AudioPlayerComponent} from '../audio-player/audio-player.component';
import {EvalCase, EvalTabComponent} from '../eval-tab/eval-tab.component';
import {EventTabComponent} from '../event-tab/event-tab.component';
import {PendingEventDialogComponent} from '../pending-event-dialog/pending-event-dialog.component';
import {DeleteSessionDialogComponent, DeleteSessionDialogData,} from '../session-tab/delete-session-dialog/delete-session-dialog.component';
import {SessionTabComponent} from '../session-tab/session-tab.component';
import {ViewImageDialogComponent} from '../view-image-dialog/view-image-dialog.component';

function fixBase64String(base64: string): string {
  // Replace URL-safe characters if they exist
  base64 = base64.replace(/-/g, '+').replace(/_/g, '/');

  // Fix base64 padding
  while (base64.length % 4 !== 0) {
    base64 += '=';
  }

  return base64;
}

class CustomPaginatorIntl extends MatPaginatorIntl {
  override nextPageLabel = 'Next Event';
  override previousPageLabel = 'Previous Event';
  override firstPageLabel = 'First Event';
  override lastPageLabel = 'Last Event';

  override getRangeLabel = (page: number, pageSize: number, length: number) => {
    if (length === 0) {
      return `Event 0 of ${length}`;
    }

    length = Math.max(length, 0);
    const startIndex = page * pageSize;

    return `Event ${startIndex + 1} of ${length}`;
  };
}

const BIDI_STREAMING_RESTART_WARNING =
    'Restarting bidirectional streaming is not currently supported. Please refresh the page or start a new session.';

@Component({
  selector: 'app-chat',
  templateUrl: './chat.component.html',
  styleUrl: './chat.component.scss',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [{provide: MatPaginatorIntl, useClass: CustomPaginatorIntl}],
})
export class ChatComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('videoContainer', {read: ElementRef}) videoContainer!: ElementRef;
  @ViewChild('sideDrawer') sideDrawer!: MatDrawer;
  @ViewChild(EventTabComponent) eventTabComponent!: EventTabComponent;
  @ViewChild(SessionTabComponent) sessionTab!: SessionTabComponent;
  @ViewChild(EvalTabComponent) evalTab!: EvalTabComponent;
  @ViewChild('autoScroll') private scrollContainer!: ElementRef;
  @ViewChild('messageTextarea') private textarea: ElementRef|undefined;
  private _snackBar = inject(MatSnackBar);
  shouldShowEvalTab = signal(true);
  enableSseIndicator = signal(false);
  isChatMode = signal(true);
  isEvalCaseEditing = signal(false);
  hasEvalCaseChanged = signal(false);
  videoElement!: HTMLVideoElement;
  currentMessage = '';
  messages: any[] = [];
  lastTextChunk: string = '';
  streamingTextMessage: any|null = null;
  latestThought: string = '';
  artifacts: any[] = [];
  userInput: string = '';
  userEditEvalCaseMessage: string = '';
  userId = 'user';
  appName = '';
  sessionId = ``;
  evalCase: EvalCase|null = null;
  updatedEvalCase: EvalCase|null = null;
  evalSetId = '';
  isAudioRecording = false;
  isVideoRecording = false;
  longRunningEvents: any[] = [];
  functionCallEventId = '';
  redirectUri = URLUtil.getBaseUrlWithoutPath();
  showSidePanel = true;
  useSse = false;
  currentSessionState = {};
  private readonly messagesSubject = new BehaviorSubject<any[]>([]);
  private readonly streamingTextMessageSubject =
      new BehaviorSubject<any|null>(null);
  private readonly scrollInterruptedSubject = new BehaviorSubject(true);
  private readonly isModelThinkingSubject = new BehaviorSubject(false);

  // TODO: Remove this once backend supports restarting bidi streaming.
  sessionHasUsedBidi = new Set<string>();

  eventData = new Map<string, any>();
  traceData: any[] = [];
  eventMessageIndexArray: any[] = [];
  renderedEventGraph: SafeHtml|undefined;
  rawSvgString: string|null = null;

  selectedEvent: any = undefined;
  selectedEventIndex: any = undefined;
  llmRequest: any = undefined;
  llmResponse: any = undefined;
  llmRequestKey = 'gcp.vertex.agent.llm_request';
  llmResponseKey = 'gcp.vertex.agent.llm_response';

  getMediaTypeFromMimetype = getMediaTypeFromMimetype;

  selectedFiles: {file: File; url: string}[] = [];
  private previousMessageCount = 0;

  protected openBase64InNewTab = openBase64InNewTab;
  protected MediaType = MediaType;

  // Sync query params with value from agent picker.
  private readonly router = inject(Router);
  private readonly activatedRoute = inject(ActivatedRoute);
  protected readonly selectedAppControl = new FormControl<string>('', {
    nonNullable: true,
  });

  private readonly changeDetectorRef = inject(ChangeDetectorRef);

  // Load apps
  private readonly agentService = inject(AgentService);
  protected isLoadingApps: WritableSignal<boolean> = signal(false);
  protected loadingError: WritableSignal<string> = signal('');
  protected readonly apps$: Observable<string[]|undefined> = of([]).pipe(
      tap(() => {
        this.isLoadingApps.set(true);
        this.selectedAppControl.disable();
      }),
      switchMap(
          () => this.agentService.listApps().pipe(
              catchError((err: HttpErrorResponse) => {
                this.loadingError.set(err.message);
                return of(undefined);
              }),
              ),
          ),
      take(1),
      tap((app) => {
        this.isLoadingApps.set(false);
        this.selectedAppControl.enable();
        if (app?.length == 1) {
          this.router.navigate([], {
            relativeTo: this.route,
            queryParams: {app: app[0]},
          });
        }
      }),
      shareReplay(),
  );

  // Trace tab 
  traceTabEnabled = true;

  constructor(
      private sanitizer: DomSanitizer,
      private sessionService: SessionService,
      private artifactService: ArtifactService,
      private audioService: AudioService,
      private webSocketService: WebSocketService,
      private videoService: VideoService,
      private dialog: MatDialog,
      private eventService: EventService,
      private route: ActivatedRoute,
      private downloadService: DownloadService,
      private evalService: EvalService,
  ) {}

  ngOnInit(): void {
    this.syncSelectedAppFromUrl();
    this.updateSelectedAppUrl();

    this.webSocketService.onCloseReason().subscribe((closeReason) => {
      const error =
          'Please check server log for full details: \n' + closeReason;
      this.openSnackBar(error, 'OK');
    });

    // OAuth HACK: Opens oauth poup in a new window. If the oauth callback
    // is successful, the new window acquires the auth token, state and
    // optionally the scope. Send this back to the main window.
    const location = new URL(window.location.href);
    const searchParams = location.searchParams;
    if (searchParams.has('code')) {
      const authResponseUrl = window.location.href;
      // Send token to the main window
      window.opener?.postMessage({authResponseUrl}, window.origin);
      // Close the popup
      window.close();
    }

    this.agentService.getApp().subscribe((app) => {
      this.appName = app;
    });

    combineLatest([
      this.agentService.getLoadingState(), this.isModelThinkingSubject
    ]).subscribe(([isLoading, isModelThinking]) => {
      const lastMessage = this.messages[this.messages.length - 1];

      if (isLoading) {
        if (!lastMessage?.isLoading && !this.streamingTextMessage) {
          this.messages.push({role: 'bot', isLoading: true});
          this.messagesSubject.next(this.messages);
        }
      } else if (lastMessage?.isLoading && !isModelThinking) {
        this.messages.pop();
        this.messagesSubject.next(this.messages);
        this.changeDetectorRef.detectChanges();
      }
    });

    combineLatest([
      this.messagesSubject, this.scrollInterruptedSubject,
      this.streamingTextMessageSubject
    ]).subscribe(([messages, scrollInterrupted, streamingTextMessage]) => {
      if (!scrollInterrupted) {
        setTimeout(() => {
          this.scrollToBottom();
        }, 100);
      }
    });
  }

  ngAfterViewInit() {
    this.showSidePanel = true;
    this.sideDrawer.open();
    // this.toggleSidePanel();
  }

  scrollToBottom() {
    setTimeout(() => {
      this.scrollContainer.nativeElement.scrollTo({
        top: this.scrollContainer.nativeElement.scrollHeight,
        behavior: 'smooth',
      });
    });
  }

  selectApp(appName: string) {
    if (appName != this.appName) {
      this.agentService.setApp(appName);
      this.createSession();
      this.eventData = new Map<string, any>();
      this.eventMessageIndexArray = [];
      this.messages = [];
      this.artifacts = [];
      this.userInput = '';
      this.longRunningEvents = [];
    }
  }

  createSession() {
    this.sessionService.createSession(this.userId, this.appName)
        .subscribe((res) => {
          this.currentSessionState = res.state;
          this.sessionId = res.id;
          this.sessionTab.refreshSession();
        });
  }

  registerUserProfile(userProfile: string){
    // this.userInput = (event.target as HTMLInputElement).value;
    // this.userInput = userProfile;
    // console.log(this.userInput);
    this.sendSecretMessage(new Event('input'), userProfile)
    // this.sendMessage(event);
  }

  // this is literally a copy/paste of sendMessage, except that
  // the user  input is not displayed back to the user.
  async sendSecretMessage(event: Event, msg: string) {
    if (this.messages.length === 0) {
      this.scrollContainer.nativeElement.addEventListener('wheel', () => {
        this.scrollInterruptedSubject.next(true);
      });
      this.scrollContainer.nativeElement.addEventListener('touchmove', () => {
        this.scrollInterruptedSubject.next(true);
      });
    }
    this.scrollInterruptedSubject.next(false);

    event.preventDefault();
    if (!msg.trim()) return;

    // Add user message
    // this.messages.push({role: 'user', text: msg});
    // this.messagesSubject.next(this.messages);
    // if (this.selectedFiles.length > 0) {
    //   const messageAttachments = this.selectedFiles.map((file) => ({
    //                                                       file: file.file,
    //                                                       url: file.url,
    //                                                     }));
    //   this.messages.push({role: 'user', attachments: messageAttachments});
    //   this.messagesSubject.next(this.messages);
    // }

    const req: AgentRunRequest = {
      appName: this.appName,
      userId: this.userId,
      sessionId: this.sessionId,
      newMessage: {
        'role': 'user',
        // 'parts': await this.getUserMessageParts(),
        'parts': [{'text': `Greetings ${msg}`}],
      },
      streaming: this.useSse,
    };
    this.selectedFiles = [];
    let index = this.eventMessageIndexArray.length - 1;
    this.streamingTextMessage = null;
    this.agentService.runSse(req).subscribe({
      next: async (chunk) => {
        if (chunk.startsWith('{"error"')) {
          this.openSnackBar(chunk, 'OK');
          return;
        }
        const chunkJson = JSON.parse(chunk);
        if (chunkJson.error) {
          this.openSnackBar(chunkJson.error, 'OK');
          return;
        }
        if (chunkJson.content) {
          for (let part of chunkJson.content.parts) {
            index += 1;
            this.processPart(chunkJson, part, index);
          }
        }
        this.changeDetectorRef.detectChanges();
      },
      error: (err) => console.error('SSE error:', err),
      complete: () => {
        this.streamingTextMessage = null;
        this.sessionTab.reloadSession(this.sessionId);
        this.eventService.getTrace(this.sessionId)
            .pipe(catchError((error) => {
              if (error.status === 404) {
                return of(null);
              }
              return of([]);
            }))
            .subscribe(res => {this.traceData = res})
      },
    });
    // Clear input
    // this.userInput = '';
    this.changeDetectorRef.detectChanges();
  }

  async sendMessage(event: Event) {
    if (this.messages.length === 0) {
      this.scrollContainer.nativeElement.addEventListener('wheel', () => {
        this.scrollInterruptedSubject.next(true);
      });
      this.scrollContainer.nativeElement.addEventListener('touchmove', () => {
        this.scrollInterruptedSubject.next(true);
      });
    }
    this.scrollInterruptedSubject.next(false);

    event.preventDefault();
    if (!this.userInput.trim()) return;

    // Add user message
    this.messages.push({role: 'user', text: this.userInput});
    this.messagesSubject.next(this.messages);
    if (this.selectedFiles.length > 0) {
      const messageAttachments = this.selectedFiles.map((file) => ({
                                                          file: file.file,
                                                          url: file.url,
                                                        }));
      this.messages.push({role: 'user', attachments: messageAttachments});
      this.messagesSubject.next(this.messages);
    }

    const req: AgentRunRequest = {
      appName: this.appName,
      userId: this.userId,
      sessionId: this.sessionId,
      newMessage: {
        'role': 'user',
        'parts': await this.getUserMessageParts(),
      },
      streaming: this.useSse,
    };
    this.selectedFiles = [];
    let index = this.eventMessageIndexArray.length - 1;
    this.streamingTextMessage = null;
    this.agentService.runSse(req).subscribe({
      next: async (chunk) => {
        if (chunk.startsWith('{"error"')) {
          this.openSnackBar(chunk, 'OK');
          return;
        }
        const chunkJson = JSON.parse(chunk);
        if (chunkJson.error) {
          this.openSnackBar(chunkJson.error, 'OK');
          return;
        }
        if (chunkJson.content) {
          for (let part of chunkJson.content.parts) {
            index += 1;
            this.processPart(chunkJson, part, index);
          }
        }
        this.changeDetectorRef.detectChanges();
      },
      error: (err) => console.error('SSE error:', err),
      complete: () => {
        this.streamingTextMessage = null;
        this.sessionTab.reloadSession(this.sessionId);
        this.eventService.getTrace(this.sessionId)
            .pipe(catchError((error) => {
              if (error.status === 404) {
                return of(null);
              }
              return of([]);
            }))
            .subscribe(res => {this.traceData = res})
      },
    });
    // Clear input
    this.userInput = '';
    this.changeDetectorRef.detectChanges();
  }

  private processPart(chunkJson: any, part: any, index: number) {
    const renderedContent =
        chunkJson.groundingMetadata?.searchEntryPoint?.renderedContent;

    if (part.text) {
      this.isModelThinkingSubject.next(false);
      const newChunk = part.text;
      if (part.thought) {
        if (newChunk !== this.latestThought) {
          this.storeEvents(part, chunkJson, index);
          let thoughtMessage = {
            role: 'bot',
            text: this.processThoughtText(newChunk),
            thought: true,
            eventId: chunkJson.id
          };

          this.insertMessageBeforeLoadingMessage(thoughtMessage);
        }
        this.latestThought = newChunk;
      } else if (!this.streamingTextMessage) {
        this.streamingTextMessage = {
          role: 'bot',
          text: this.processThoughtText(newChunk),
          thought: part.thought ? true : false,
          eventId: chunkJson.id
        };

        if (renderedContent) {
          this.streamingTextMessage.renderedContent =
              chunkJson.groundingMetadata.searchEntryPoint.renderedContent;
        }

        this.insertMessageBeforeLoadingMessage(this.streamingTextMessage);

        if (!this.useSse) {
          this.storeEvents(part, chunkJson, index);
          this.eventMessageIndexArray[index] = newChunk;
          this.streamingTextMessage = null;
          return;
        }
      } else {
        if (renderedContent) {
          this.streamingTextMessage.renderedContent =
              chunkJson.groundingMetadata.searchEntryPoint.renderedContent;
        }

        if (newChunk == this.streamingTextMessage.text) {
          this.storeEvents(part, chunkJson, index);
          this.eventMessageIndexArray[index] = newChunk;
          this.streamingTextMessage = null;
          return;
        }
        this.streamingTextMessage.text += newChunk;
        this.streamingTextMessageSubject.next(this.streamingTextMessage);
      }
    } else if (!part.thought) {
      this.isModelThinkingSubject.next(false);
      this.storeEvents(part, chunkJson, index);
      this.storeMessage(
          part, chunkJson, index, chunkJson.author === 'user' ? 'user' : 'bot');
    } else {
      this.isModelThinkingSubject.next(true);
    }
  }

  async getUserMessageParts() {
    let parts: any = [{'text': `${this.userInput}`}];
    if (this.selectedFiles.length > 0) {
      for (const file of this.selectedFiles) {
        parts.push({
          inlineData: {
            displayName: file.file.name,
            data: await this.readFileAsBytes(file.file),
            mimeType: file.file.type,
          },
        });
      }
    }
    return parts;
  }

  readFileAsBytes(file: File): Promise<ArrayBuffer> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        const base64Data = e.target.result.split(',')[1];
        resolve(base64Data);
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);  // Read as raw bytes
    });
  }

  private updateRedirectUri(urlString: string, newRedirectUri: string): string {
    try {
      const url = new URL(urlString);
      const searchParams = url.searchParams;
      searchParams.set('redirect_uri', newRedirectUri);
      return url.toString();
    } catch (error) {
      console.warn('Failed to update redirect URI: ', error);
      return urlString;
    }
  }

  private storeMessage(
      part: any, e: any, index: number, role: string, invocationIndex?: number,
      finalResponsePartIndex?: number) {
    if (e?.longRunningToolIds && e.longRunningToolIds.length > 0) {
      this.getAsyncFunctionsFromParts(e.longRunningToolIds, e.content.parts);
      const func = this.longRunningEvents[0];
      if (func.args.authConfig &&
          func.args.authConfig.exchangedAuthCredential &&
          func.args.authConfig.exchangedAuthCredential.oauth2) {
        // for OAuth
        const authUri =
            func.args.authConfig.exchangedAuthCredential.oauth2.authUri;
        const updatedAuthUri = this.updateRedirectUri(
            authUri,
            this.redirectUri,
        );
        this.openOAuthPopup(updatedAuthUri)
            .then((authResponseUrl) => {
              this.functionCallEventId = e.id;
              this.sendOAuthResponse(func, authResponseUrl, this.redirectUri);
            })
            .catch((error) => {
              console.error('OAuth Error:', error);
            });
      } else {
        this.functionCallEventId = e.id;
      }
    }
    if (e?.actions && e.actions.artifactDelta) {
      for (const key in e.actions.artifactDelta) {
        if (e.actions.artifactDelta.hasOwnProperty(key)) {
          this.renderArtifact(key, e.actions.artifactDelta[key]);
        }
      }
    }

    let message: any = {
      role,
      evalStatus: e?.evalStatus,
      actualInvocationToolUses: e?.actualInvocationToolUses,
      expectedInvocationToolUses: e?.expectedInvocationToolUses,
      invocationIndex: invocationIndex !== undefined ? invocationIndex :
                                                       undefined,
      finalResponsePartIndex: finalResponsePartIndex !== undefined ?
          finalResponsePartIndex :
          undefined,
    };
    if (part.inlineData) {
      const base64Data =
          this.formatBase64Data(part.inlineData.data, part.inlineData.mimeType);
      message.inlineData = {
        displayName: part.inlineData.displayName,
        data: base64Data,
        mimeType: part.inlineData.mimeType,
      };
      this.eventMessageIndexArray[index] = part.inlineData;
    } else if (part.text) {
      message.text = part.text;
      message.thought = part.thought ? true : false;
      if (e?.groundingMetadata && e.groundingMetadata.searchEntryPoint &&
          e.groundingMetadata.searchEntryPoint.renderedContent) {
        message.renderedContent =
            e.groundingMetadata.searchEntryPoint.renderedContent;
      }
      this.eventMessageIndexArray[index] = part.text;
    } else if (part.functionCall) {
      message.functionCall = part.functionCall;
      message.eventId = e?.id;
      this.eventMessageIndexArray[index] = part.functionCall;
    } else if (part.functionResponse) {
      message.functionResponse = part.functionResponse;
      message.eventId = e?.id;
      this.eventMessageIndexArray[index] = part.functionResponse;
    } else if (part.executableCode) {
      message.executableCode = part.executableCode;
      this.eventMessageIndexArray[index] = part.executableCode;
    } else if (part.codeExecutionResult) {
      message.codeExecutionResult = part.codeExecutionResult;
      this.eventMessageIndexArray[index] = part.codeExecutionResult;
      if (e.actions && e.actions.artifact_delta) {
        for (const key in e.actions.artifact_delta) {
          if (e.actions.artifact_delta.hasOwnProperty(key)) {
            this.renderArtifact(key, e.actions.artifact_delta[key]);
          }
        }
      }
    }

    if (Object.keys(part).length > 0) {
      this.insertMessageBeforeLoadingMessage(message);
    }
  }

  private insertMessageBeforeLoadingMessage(message: any) {
    const lastMessage = this.messages[this.messages.length - 1];
    if (lastMessage?.isLoading) {
      this.messages.splice(this.messages.length - 1, 0, message);
    } else {
      this.messages.push(message);
    }
    this.messagesSubject.next(this.messages);
  }

  private formatBase64Data(data: string, mimeType: string) {
    const fixedBase64Data = fixBase64String(data);
    return `data:${mimeType};base64,${fixedBase64Data}`;
  }

  private renderArtifact(artifactId: string, versionId: string) {
    // Add a placeholder message for the artifact
    // Feed the placeholder with the artifact data after it's fetched
    let message = {
      role: 'bot',
      inlineData: {
        data: '',
        mimeType: 'image/png',
      },
    };
    this.insertMessageBeforeLoadingMessage(message);

    const currentIndex = this.messages.length - 2;

    this.artifactService
        .getArtifactVersion(
            this.userId,
            this.appName,
            this.sessionId,
            artifactId,
            versionId,
            )
        .subscribe((res) => {
          const mimeType = res.inlineData.mimeType;
          const base64Data =
              this.formatBase64Data(res.inlineData.data, mimeType);

          const mediaType = getMediaTypeFromMimetype(mimeType);

          let inlineData = {
            name: this.createDefaultArtifactName(mimeType),
            data: base64Data,
            mimeType: mimeType,
            mediaType,
          };

          this.messages[currentIndex] = {
            role: 'bot',
            inlineData,
          };

          // To trigger ngOnChanges in the artifact tab component
          this.artifacts = [
            ...this.artifacts,
            {
              id: artifactId,
              data: base64Data,
              mimeType,
              versionId,
              mediaType: getMediaTypeFromMimetype(mimeType),
            },
          ];
        });
  }

  private storeEvents(part: any, e: any, index: number) {
    let title = '';
    if (part.text) {
      title += 'text:' + part.text;
    } else if (part.functionCall) {
      title += 'functionCall:' + part.functionCall.name;
    } else if (part.functionResponse) {
      title += 'functionResponse:' + part.functionResponse.name;
    } else if (part.executableCode) {
      title += 'executableCode:' + part.executableCode.code.slice(0, 10);
    } else if (part.codeExecutionResult) {
      title += 'codeExecutionResult:' + part.codeExecutionResult.outcome;
    }
    e.title = title;

    this.eventData.set(e.id, e);
    this.eventData = new Map(this.eventData);
  }

  private sendOAuthResponse(
      func: any,
      authResponseUrl: string,
      redirectUri: string,
  ) {
    this.longRunningEvents.pop();
    const authResponse: AgentRunRequest = {
      appName: this.appName,
      userId: this.userId,
      sessionId: this.sessionId,
      newMessage: {
        'role': 'user',
        'parts': [],
      },
    };

    var authConfig = structuredClone(func.args.authConfig);
    authConfig.exchangedAuthCredential.oauth2.authResponseUri = authResponseUrl;
    authConfig.exchangedAuthCredential.oauth2.redirectUri = redirectUri;

    authResponse.functionCallEventId = this.functionCallEventId;
    authResponse.newMessage.parts.push({
      'function_response': {
        id: func.id,
        name: func.name,
        response: authConfig,
      },
    });
    this.agentService.run(authResponse).subscribe((res) => {
      this.processRunResponse(res);
    });
  }

  private processRunResponse(response: any) {
    let index = this.eventMessageIndexArray.length - 1;
    for (const e of response) {
      if (e.content) {
        for (let part of e.content.parts) {
          index += 1;
          this.processPart(e, part, index);
        }
      }
    }
  }

  openDialog(): void {
    const dialogRef = this.dialog.open(PendingEventDialogComponent, {
      width: '600px',
      data: {
        event: this.longRunningEvents[0],
        appName: this.appName,
        userId: this.userId,
        sessionId: this.sessionId,
        functionCallEventId: this.functionCallEventId,
      },
    });

    dialogRef.afterClosed().subscribe((t) => {
      if (t) {
        this.removeFinishedLongRunningEvents(t.events);
        this.processRunResponse(t.response);
      }
    });
  }

  removeFinishedLongRunningEvents(finishedEvents: any[]) {
    const idsToExclude = new Set(finishedEvents.map((obj: any) => obj.id));
    this.longRunningEvents =
        this.longRunningEvents.filter(obj => !idsToExclude.has(obj.id));
  }

  clickEvent(i: number) {
    const key = this.messages[i].eventId;

    this.sideDrawer.open();
    this.showSidePanel = true;
    this.selectedEvent = this.eventData.get(key);
    this.selectedEventIndex = this.getIndexOfKeyInMap(key);

    this.eventService.getEventTrace(this.selectedEvent.id).subscribe((res) => {
      this.llmRequest = JSON.parse(res[this.llmRequestKey]);
      this.llmResponse = JSON.parse(res[this.llmResponseKey]);
    });

    this.eventService
        .getEvent(
            this.userId,
            this.appName,
            this.sessionId,
            this.selectedEvent.id,
            )
        .subscribe(async (res) => {
          if (!res.dotSrc) {
            this.renderedEventGraph = undefined;
            return;
          }
          const graphSrc = res.dotSrc;
          const viz = await instance();
          const svg = viz.renderString(graphSrc, {
            format: 'svg',
            engine: 'dot',
          });
          this.rawSvgString = svg;
          this.renderedEventGraph = this.sanitizer.bypassSecurityTrustHtml(svg);
        });
  }

  userMessagesLength(i: number) {
    return this.messages.slice(0, i).filter((m) => m.role == 'user').length;
  }

  ngOnDestroy(): void {
    this.webSocketService.closeConnection();
  }

  onAppSelection(event: any) {
    if (this.isAudioRecording) {
      this.stopAudioRecording();
      this.isAudioRecording = false;
    }
    if (this.isVideoRecording) {
      this.stopVideoRecording();
      this.isVideoRecording = false;
    }
  }

  toggleAudioRecording() {
    this.isAudioRecording ? this.stopAudioRecording() :
                            this.startAudioRecording();
  }

  startAudioRecording() {
    if (this.sessionHasUsedBidi.has(this.sessionId)) {
      this.openSnackBar(BIDI_STREAMING_RESTART_WARNING, 'OK')
      return;
    }

    this.isAudioRecording = true;
    const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
    this.webSocketService.connect(
        `${protocol}://${URLUtil.getWSServerUrl()}/run_live?app_name=${
            this.appName}&user_id=${this.userId}&session_id=${this.sessionId}`,
    );
    this.audioService.startRecording();
    this.messages.push({role: 'user', text: 'Speaking...'});
    this.messages.push({role: 'bot', text: 'Speaking...'});
    this.messagesSubject.next(this.messages);
    this.sessionHasUsedBidi.add(this.sessionId);
  }

  stopAudioRecording() {
    this.audioService.stopRecording();
    this.webSocketService.closeConnection();
    this.isAudioRecording = false;
  }

  toggleVideoRecording() {
    this.isVideoRecording ? this.stopVideoRecording() :
                            this.startVideoRecording();
  }

  startVideoRecording() {
    if (this.sessionHasUsedBidi.has(this.sessionId)) {
      this.openSnackBar(BIDI_STREAMING_RESTART_WARNING, 'OK')
      return;
    }

    this.isVideoRecording = true;
    const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
    this.webSocketService.connect(
        `${protocol}://${URLUtil.getWSServerUrl()}/run_live?app_name=${
            this.appName}&user_id=${this.userId}&session_id=${this.sessionId}`,
    );
    this.videoService.startRecording(this.videoContainer);
    this.audioService.startRecording();
    this.messages.push({role: 'user', text: 'Speaking...'});
    this.messagesSubject.next(this.messages);
    this.sessionHasUsedBidi.add(this.sessionId);
  }

  stopVideoRecording() {
    this.audioService.stopRecording();
    this.videoService.stopRecording(this.videoContainer);
    this.webSocketService.closeConnection();
    this.isVideoRecording = false;
  }

  private getAsyncFunctionsFromParts(pendingIds: any[], parts: any[]) {
    for (const part of parts) {
      if (part.functionCall && pendingIds.includes(part.functionCall.id)) {
        this.longRunningEvents.push(part.functionCall);
      }
    }
  }

  private openOAuthPopup(url: string): Promise<any> {
    return new Promise((resolve, reject) => {
      // Open OAuth popup
      const popup = window.open(url, 'oauthPopup', 'width=600,height=700');

      if (!popup) {
        reject('Popup blocked!');
        return;
      }

      // Listen for messages from the popup
      window.addEventListener(
          'message',
          (event) => {
            if (event.origin !== window.location.origin) {
              return;  // Ignore messages from unknown sources
            }
            const {authResponseUrl} = event.data;
            if (authResponseUrl) {
              resolve(authResponseUrl);
            } else {
              reject('OAuth failed');
            }
          },
          {once: true},
      );
    });
  }

  toggleSidePanel() {
    if (this.showSidePanel) {
      this.sideDrawer.close();
    } else {
      this.sideDrawer.open();
    }
    this.showSidePanel = !this.showSidePanel;
  }

  protected handleTabChange(event: any) {
    if (!this.isChatMode()) {
      this.handleReturnToSession(true);
    }
  }

  protected handleShouldShowEvalTab(shouldShow: boolean) {
    this.shouldShowEvalTab.set(shouldShow);
  }

  protected handleReturnToSession(event: boolean) {
    this.sessionTab.getSession(this.sessionId);
    this.isChatMode.set(true);
  }

  protected handleEvalNotInstalled(errorMsg: string) {
    if (errorMsg) {
      this.openSnackBar(errorMsg, 'OK');
    }
  }

  private resetEventsAndMessages() {
    this.eventData.clear();
    this.eventMessageIndexArray = [];
    this.messages = [];
    this.messagesSubject.next(this.messages);
    this.artifacts = [];
  }

  protected updateWithSelectedSession(session: Session) {
    if (!session || !session.id || !session.events || !session.state) {
      return;
    }

    this.sessionId = session.id;
    this.currentSessionState = session.state;
    this.evalCase = null;
    this.isChatMode.set(true);

    this.resetEventsAndMessages();
    let index = 0;

    session.events.forEach((event: any) => {
      event.content?.parts?.forEach((part: any) => {
        this.storeMessage(
            part, event, index, event.author === 'user' ? 'user' : 'bot');
        index += 1;
        if (event.author && event.author !== 'user') {
          this.storeEvents(part, event, index);
        }
      });
    });

    this.eventService.getTrace(this.sessionId).subscribe(res => {
      this.traceData = res;
    })
  }

  protected updateWithSelectedEvalCase(evalCase: EvalCase) {
    this.evalCase = evalCase;
    this.isChatMode.set(false);

    this.resetEventsAndMessages();
    let index = 0;
    let invocationIndex = 0;

    for (const invocation of evalCase.conversation) {
      if (invocation.userContent?.parts) {
        for (const part of invocation.userContent.parts) {
          this.storeMessage(part, null, index, 'user');
          index++;
        }
      }

      if (invocation.intermediateData?.toolUses) {
        for (const toolUse of invocation.intermediateData.toolUses) {
          const functionCallPart = {functionCall: {name: toolUse.name}};
          this.storeMessage(functionCallPart, null, index, 'bot');
          index++;

          const functionResponsePart = {functionResponse: {name: toolUse.name}};
          this.storeMessage(functionResponsePart, null, index, 'bot');
          index++;
        }
      }

      if (invocation.finalResponse?.parts) {
        let finalResponsePartIndex = 0;
        for (const part of invocation.finalResponse.parts) {
          this.storeMessage(
              part, null, index, 'bot', invocationIndex,
              finalResponsePartIndex);
          index++;
          finalResponsePartIndex++;
        }
      }
      invocationIndex++;
    }
  }

  protected updateSelectedEvalSetId(evalSetId: string) {
    this.evalSetId = evalSetId;
  }

  protected editEvalCase(message: any) {
    this.isEvalCaseEditing.set(true);
    this.userEditEvalCaseMessage = message.text;
    message.isEditing = true;
    setTimeout(() => {
      this.textarea?.nativeElement.focus();
      let textLength = this.textarea?.nativeElement.value.length;
      if (message.text.charAt(textLength - 1) === '\n') {
        textLength--;
      }
      this.textarea?.nativeElement.setSelectionRange(textLength, textLength);
    }, 0);
  }

  protected saveEvalCase() {
    this.evalService
        .updateEvalCase(
            this.appName, this.evalSetId, this.updatedEvalCase!.evalId,
            this.updatedEvalCase!)
        .subscribe((res) => {
          this.openSnackBar('Eval case updated', 'OK');
          this.hasEvalCaseChanged.set(false);
        });
  }

  protected cancelEditEvalCase() {
    this.hasEvalCaseChanged.set(false);
    this.isEvalCaseEditing.set(false);
    this.updatedEvalCase = null;
    this.updateWithSelectedEvalCase(this.evalCase!);
  }

  protected cancelEditMessage(message: any) {
    message.isEditing = false;
    this.isEvalCaseEditing.set(false);
  }

  protected saveEditMessage(message: any) {
    this.hasEvalCaseChanged.set(true);
    this.isEvalCaseEditing.set(false);
    message.isEditing = false;
    message.text =
        this.userEditEvalCaseMessage ? this.userEditEvalCaseMessage : ' ';

    this.updatedEvalCase = structuredClone(this.evalCase!);
    this.updatedEvalCase!.conversation[message.invocationIndex]
        .finalResponse!.parts![message.finalResponsePartIndex] = {
      text: this.userEditEvalCaseMessage
    };

    this.userEditEvalCaseMessage = '';
  }

  protected deleteEvalCaseMessage(message: any, index: number) {
    this.hasEvalCaseChanged.set(true);
    this.messages.splice(index, 1);
    this.messagesSubject.next(this.messages);

    this.updatedEvalCase = structuredClone(this.evalCase!);
    this.updatedEvalCase!.conversation[message.invocationIndex]
        .finalResponse!.parts!.splice(message.finalResponsePartIndex, 1);
  }

  protected deleteEvalCase() {
    const dialogData: DeleteSessionDialogData = {
      title: 'Confirm delete',
      message: `Are you sure you want to delete ${this.evalCase!.evalId}?`,
      confirmButtonText: 'Delete',
      cancelButtonText: 'Cancel',
    };

    const dialogRef = this.dialog.open(DeleteSessionDialogComponent, {
      width: '600px',
      data: dialogData,
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.evalTab.deleteEvalCase(this.evalCase!.evalId);
        this.openSnackBar('Eval case deleted', 'OK')
      }
    });
  }

  protected updateSessionState(session: Session) {
    this.currentSessionState = session.state;
  }

  onNewSessionClick() {
    this.createSession();
    this.eventData.clear();
    this.eventMessageIndexArray = [];
    this.messages = [];
    this.artifacts = [];

    // Close eval history if opened
    if (!!this.evalTab.showEvalHistory) {
      this.evalTab.toggleEvalHistoryButton();
    }
  }

  onFileSelect(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files) {
      for (let i = 0; i < input.files.length; i++) {
        const file = input.files[i];
        const url = URL.createObjectURL(file);
        this.selectedFiles.push({file, url});
      }
    }
    input.value = '';
  }

  removeFile(index: number) {
    URL.revokeObjectURL(this.selectedFiles[index].url);
    this.selectedFiles.splice(index, 1);
  }

  toggleSse() {
    this.useSse = !this.useSse;
  }

  selectEvent(key: string) {
    this.selectedEvent = this.eventData.get(key);
    this.selectedEventIndex = this.getIndexOfKeyInMap(key);
    this.eventService.getEventTrace(this.selectedEvent.id).subscribe((res) => {
      this.llmRequest = JSON.parse(res[this.llmRequestKey]);
      this.llmResponse = JSON.parse(res[this.llmResponseKey]);
    });
    this.eventService
        .getEvent(
            this.userId,
            this.appName,
            this.sessionId,
            this.selectedEvent.id,
            )
        .subscribe(async (res) => {
          if (!res.dotSrc) {
            this.renderedEventGraph = undefined;
            return;
          }
          const graphSrc = res.dotSrc;
          const viz = await instance();
          const svg = viz.renderString(graphSrc, {
            format: 'svg',
            engine: 'dot',
          });
          this.rawSvgString = svg;
          this.renderedEventGraph = this.sanitizer.bypassSecurityTrustHtml(svg);
        });
  }

  protected deleteSession(session: string) {
    const dialogData: DeleteSessionDialogData = {
      title: 'Confirm delete',
      message:
          `Are you sure you want to delete this session ${this.sessionId}?`,
      confirmButtonText: 'Delete',
      cancelButtonText: 'Cancel',
    };

    const dialogRef = this.dialog.open(DeleteSessionDialogComponent, {
      width: '600px',
      data: dialogData,
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.sessionService.deleteSession(this.userId, this.appName, session)
            .subscribe((res) => {
              const nextSession = this.sessionTab.refreshSession(session);
              if (nextSession) {
                this.sessionTab.getSession(nextSession.id);
              } else {
                window.location.reload();
              }
            });
      } else {
      }
    });
  }

  private syncSelectedAppFromUrl() {
    combineLatest([
      this.router.events.pipe(
          filter((e) => e instanceof NavigationEnd),
          map(() => this.activatedRoute.snapshot.queryParams),
          ),
      this.apps$
    ]).subscribe(([params, apps]) => {
      if (apps && apps.length) {
        const app = params['app'];
        if (app && apps.includes(app)) {
          this.selectedAppControl.setValue(app);
        } else if (app) {
          this.openSnackBar(`Agent '${app}' not found`, 'OK');
        }
      }
    });
  }

  private updateSelectedAppUrl() {
    this.selectedAppControl.valueChanges
        .pipe(distinctUntilChanged(), filter(Boolean))
        .subscribe((app: string) => {
          this.selectApp(app);

          // Navigate if selected app changed.
          const selectedAgent = this.activatedRoute.snapshot.queryParams['app'];
          if (app === selectedAgent) {
            return;
          }
          this.router.navigate([], {
            queryParams: {'app': app},
            queryParamsHandling: 'merge',
          });
        });
  }

  handlePageEvent(event: any) {
    if (event.pageIndex >= 0) {
      const key = this.getKeyAtIndexInMap(event.pageIndex);
      if (key) {
        this.selectEvent(key);
      }
    }
  }

  closeSelectedEvent() {
    this.selectedEvent = undefined;
    this.selectedEventIndex = undefined;
  }

  private getIndexOfKeyInMap(key: string): number|undefined {
    let index = 0;
    const mapOrderPreservingSort = (a: any, b: any): number =>
        0;  // Simple compare function

    const sortedKeys = Array.from(this.eventData.keys())
                           .sort(
                               mapOrderPreservingSort,
                           );

    for (const k of sortedKeys) {
      if (k === key) {
        return index;
      }
      index++;
    }
    return undefined;  // Key not found
  }

  private getKeyAtIndexInMap(index: number): string|undefined {
    const mapOrderPreservingSort = (a: any, b: any): number =>
        0;  // Simple compare function

    const sortedKeys = Array.from(this.eventData.keys())
                           .sort(
                               mapOrderPreservingSort,
                           );

    if (index >= 0 && index < sortedKeys.length) {
      return sortedKeys[index];
    }
    return undefined;  // Index out of bounds
  }

  openSnackBar(message: string, action: string) {
    this._snackBar.open(message, action);
  }

  private processThoughtText(text: string) {
    return text.replace('/*PLANNING*/', '').replace('/*ACTION*/', '');
  }

  openLink(url: string) {
    window.open(url, '_blank');
  }

  renderGooglerSearch(content: string) {
    return this.sanitizer.bypassSecurityTrustHtml(content);
  }

  openViewImageDialog(imageData: string|null) {
    const dialogRef = this.dialog.open(ViewImageDialogComponent, {
      maxWidth: '90vw',
      maxHeight: '90vh',
      data: {
        imageData,
      },
    });
  }

  private createDefaultArtifactName(mimeType: string): string {
    if (!mimeType || !mimeType.includes('/')) {
      return '';
    }

    return mimeType.replace('/', '.');
  }

  protected exportSession() {
    this.sessionService.getSession(this.userId, this.appName, this.sessionId)
        .subscribe((res) => {
          console.log(res);
          this.downloadService.downloadObjectAsJson(
              res, `session-${this.sessionId}.json`);
        });
  }
}
