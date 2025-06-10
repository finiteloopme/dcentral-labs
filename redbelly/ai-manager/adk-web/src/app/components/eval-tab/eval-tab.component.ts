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

import {SelectionModel} from '@angular/cdk/collections';
import {ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, inject, Input, OnChanges, OnInit, Output, QueryList, signal, SimpleChanges, ViewChildren} from '@angular/core';
import {MatCheckbox} from '@angular/material/checkbox';
import {MatDialog} from '@angular/material/dialog';
import {MatTableDataSource} from '@angular/material/table';
import {BehaviorSubject, of} from 'rxjs';
import {catchError} from 'rxjs/operators';

import {Session} from '../../core/models/Session';
import {Invocation} from '../../core/models/types';
import {EvalService} from '../../core/services/eval.service';
import {FeatureFlagService} from '../../core/services/feature-flag.service';
import {SessionService} from '../../core/services/session.service';

import {AddEvalSessionDialogComponent} from './add-eval-session-dialog/add-eval-session-dialog/add-eval-session-dialog.component';
import {NewEvalSetDialogComponentComponent} from './new-eval-set-dialog/new-eval-set-dialog-component/new-eval-set-dialog-component.component';
import {EvalMetric, RunEvalConfigDialogComponent} from './run-eval-config-dialog/run-eval-config-dialog.component';

export interface EvalCase {
  evalId: string;
  conversation: Invocation[];
  sessionInput: any;
  creationTimestamp: number;
}

interface EvaluationResult {
  setId: string;
  evalId: string;
  finalEvalStatus: number;
  evalMetricResults: any[];
  overallEvalMetricResults: any[];
  evalMetricResultPerInvocation?: any[];
  sessionId: string;
  sessionDetails: any;
}

interface UIEvaluationResult {
  isToggled: boolean;
  evaluationResults: EvaluationResult[];
}

// Key: result timestamp
// Value: EvaluationResult
interface CaseEvaluationResult {
  [key: string]: UIEvaluationResult;
}

// Key: setId
// Value: CaseEvaluationResult
interface SetEvaluationResult {
  [key: string]: CaseEvaluationResult;
}


// Key: appId
// Value: SetEvaluationResult
interface AppEvaluationResult {
  [key: string]: SetEvaluationResult;
}


@Component({
  selector: 'app-eval-tab',
  templateUrl: './eval-tab.component.html',
  styleUrl: './eval-tab.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class EvalTabComponent implements OnInit, OnChanges {
  @ViewChildren(MatCheckbox) checkboxes!: QueryList<MatCheckbox>;
  @Input() appName: string = '';
  @Input() userId: string = '';
  @Input() sessionId: string = '';
  @Output() readonly sessionSelected = new EventEmitter<Session>();
  @Output() readonly shouldShowTab = new EventEmitter<boolean>();
  @Output() readonly evalNotInstalledMsg = new EventEmitter<string>();
  @Output() readonly evalCaseSelected = new EventEmitter<EvalCase>();
  @Output() readonly evalSetIdSelected = new EventEmitter<string>();
  @Output() readonly shouldReturnToSession = new EventEmitter<boolean>();

  private readonly evalCasesSubject = new BehaviorSubject<string[]>([]);
  private readonly changeDetectorRef = inject(ChangeDetectorRef);
  private readonly flagService = inject(FeatureFlagService);

  protected readonly isViewEvalCaseEnabled =
      this.flagService.isViewEvalCaseEnabled();
  protected readonly isSetEvalConfigEnabled =
      this.flagService.isSetEvalConfigEnabled();

  displayedColumns: string[] = ['select', 'evalId', 'finalEvalStatus'];
  evalsets: any[] = [];
  selectedEvalSet: string = '';
  evalCases: string[] = [];
  selectedEvalCase: EvalCase|null = null;
  deletedEvalCaseIndex: number = -1;

  dataSource = new MatTableDataSource<string>(this.evalCases);
  selection = new SelectionModel<string>(true, []);

  showEvalHistory = signal(false);

  evalRunning = signal(false);
  evalMetrics: EvalMetric[] = [
    {
      metricName: 'tool_trajectory_avg_score',
      threshold: 1,
    },
    {
      metricName: 'response_match_score',
      threshold: 0.7,
    }
  ];
  evalResult: EvaluationResult[] = [];
  readonly dialog = inject(MatDialog);

  protected appEvaluationResults: AppEvaluationResult = {};

  constructor(
      private evalService: EvalService,
      private sessionService: SessionService,
  ) {
    this.evalCasesSubject.subscribe((evalCases: string[]) => {
      if (!this.selectedEvalCase && this.deletedEvalCaseIndex >= 0 &&
          evalCases.length > 0) {
        this.selectNewEvalCase(evalCases);
        this.deletedEvalCaseIndex = -1;
      } else if (evalCases.length === 0) {
        this.shouldReturnToSession.emit(true);
      }
    });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['appName']) {
      this.selectedEvalSet = '';
      this.evalCases = [];
      this.getEvalSet();
      this.getEvaluationResult();
    }
  }
  ngOnInit(): void {}

  selectNewEvalCase(evalCases: string[]) {
    let caseToSelect = this.deletedEvalCaseIndex;
    if (this.deletedEvalCaseIndex === evalCases.length) {
      caseToSelect = 0;
    }
    this.getEvalCase(evalCases[caseToSelect]);
  }

  getEvalSet() {
    if (this.appName != '') {
      this.evalService.getEvalSets(this.appName)
          .pipe(catchError((error) => {
            if (error.status === 404 && error.statusText === 'Not Found') {
              this.shouldShowTab.emit(false);
              return of(null);
            }
            return of([]);
          }))
          .subscribe((sets) => {
            if (sets !== null) {
              this.shouldShowTab.emit(true);
              this.evalsets = sets;
            }
          });
      ;
    }
  }

  openNewEvalSetDialog() {
    const dialogRef = this.dialog.open(NewEvalSetDialogComponentComponent, {
      width: '600px',
      data: {appName: this.appName},
    });

    dialogRef.afterClosed().subscribe((needRefresh) => {
      if (needRefresh) {
        this.getEvalSet();
      }
    });
  }

  openNewEvalCaseDialog() {
    const dialogRef = this.dialog.open(AddEvalSessionDialogComponent, {
      width: '600px',
      data: {
        appName: this.appName,
        userId: this.userId,
        sessionId: this.sessionId,
        evalSetId: this.selectedEvalSet,
      },
    });

    dialogRef.afterClosed().subscribe((needRefresh) => {
      if (needRefresh) {
        this.listEvalCases();
      }
    });
  }

  listEvalCases() {
    this.evalCases = [];
    this.evalService.listEvalCases(this.appName, this.selectedEvalSet)
        .subscribe((res) => {
          this.evalCases = res;
          this.dataSource = new MatTableDataSource<string>(this.evalCases);
          this.evalCasesSubject.next(this.evalCases);
          this.changeDetectorRef.detectChanges();
        });
  }

  runEval() {
    this.evalRunning.set(true);
    if (this.selection.selected.length == 0) {
      alert('No case selected!');
      this.evalRunning.set(false);
      return;
    }
    this.evalService
        .runEval(
            this.appName,
            this.selectedEvalSet,
            this.selection.selected,
            this.evalMetrics,
            )
        .pipe(catchError((error) => {
          if (error.error?.detail?.includes('not installed')) {
            this.evalNotInstalledMsg.emit(error.error.detail);
          }
          return of([]);
        }))
        .subscribe((res) => {
          this.evalRunning.set(false);
          this.evalResult = res;

          this.getEvaluationResult();
        });
  }

  selectEvalSet(set: string) {
    this.selectedEvalSet = set;
    this.listEvalCases();
  }

  clearSelectedEvalSet() {
    if (!!this.showEvalHistory()) {
      this.toggleEvalHistoryButton();
      return;
    }
    this.selectedEvalSet = '';
  }

  isAllSelected() {
    const numSelected = this.selection.selected.length;
    const numRows = this.dataSource.data.length;
    return numSelected === numRows;
  }

  toggleAllRows() {
    if (this.isAllSelected()) {
      this.selection.clear();
      return;
    }

    this.selection.select(...this.dataSource.data);
  }

  getEvalResultForCase(caseId: string) {
    const el = this.evalResult.filter((c) => c.evalId == caseId);
    if (el.length == 0) {
      return undefined;
    }
    return el[0].finalEvalStatus;
  }

  private formatToolUses(toolUses: any[]): any[] {
    const formattedToolUses = [];
    for (const toolUse of toolUses) {
      formattedToolUses.push({name: toolUse.name, args: toolUse.args});
    }
    return formattedToolUses;
  }

  private addEvalCaseResultToEvents(
      res: any, evalCaseResult: EvaluationResult) {
    const invocationResults = evalCaseResult.evalMetricResultPerInvocation!;
    let currentInvocationIndex = -1;

    if (invocationResults) {
      for (let i = 0; i < res.events.length; i++) {
        const event = res.events[i];
        if (event.author === 'user') {
          currentInvocationIndex++;
        } else {
          const invocationResult = invocationResults[currentInvocationIndex];
          event.evalStatus = invocationResult.evalMetricResults[0].evalStatus;

          if (i === res.events.length - 1 ||
              res.events[i + 1].author === 'user') {
            event.actualInvocationToolUses = this.formatToolUses(
                invocationResult.actualInvocation.intermediateData.toolUses);
            event.expectedInvocationToolUses = this.formatToolUses(
                invocationResult.expectedInvocation.intermediateData.toolUses);
          }
        }
      }
    }
    return res;
  }

  private fromApiResultToSession(res: any): Session {
    return {
      id: res?.id ?? '',
      appName: res?.appName ?? '',
      userId: res?.userId ?? '',
      state: res?.state ?? [],
      events: res?.events ?? [],
    };
  }

  getSession(evalId: string) {
    const evalCaseResult = this.evalResult.filter((c) => c.evalId == evalId)[0];
    const sessionId = evalCaseResult.sessionId;
    this.sessionService.getSession(this.userId, this.appName, sessionId)
        .subscribe((res) => {
          this.addEvalCaseResultToEvents(res, evalCaseResult);
          const session = this.fromApiResultToSession(res);

          this.sessionSelected.emit(session);
        });
  }

  toggleEvalHistoryButton() {
    this.showEvalHistory.set(!this.showEvalHistory());
  }

  protected getEvalHistoryOfCurrentSet() {
    return this.appEvaluationResults[this.appName][this.selectedEvalSet];
  }

  protected getEvalHistoryOfCurrentSetSorted(): any[] {
    const evalHistory = this.getEvalHistoryOfCurrentSet();
    const evalHistorySorted =
        Object.keys(evalHistory).sort((a, b) => b.localeCompare(a));

    const evalHistorySortedArray = evalHistorySorted.map((key) => {
      return {timestamp: key, evaluationResults: evalHistory[key]};
    });

    return evalHistorySortedArray;
  }

  protected getPassCountForCurrentResult(result: any[]) {
    return result.filter((r: any) => r.finalEvalStatus == 1).length;
  }

  protected getFailCountForCurrentResult(result: any[]) {
    return result.filter((r: any) => r.finalEvalStatus == 2).length;
  }

  protected formatTimestamp(timestamp: number|string): string {
    const numericTimestamp = Number(timestamp);

    if (isNaN(numericTimestamp)) {
      return 'Invalid timestamp provided';
    }

    const date = new Date(numericTimestamp * 1000);

    if (isNaN(date.getTime())) {
      return 'Invalid date created from timestamp';
    }

    const options: Intl.DateTimeFormatOptions = {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    };

    return new Intl.DateTimeFormat('en-US', options).format(date);
  }

  getEvaluationStatusCardActionButtonIcon(timestamp: number|string) {
    return this.getEvalHistoryOfCurrentSet()[timestamp].isToggled ?
        'keyboard_arrow_up' :
        'keyboard_arrow_down';
  }

  toggleHistoryStatusCard(timestamp: number|string) {
    this.getEvalHistoryOfCurrentSet()[timestamp].isToggled =
        !this.getEvalHistoryOfCurrentSet()[timestamp].isToggled;
  }

  isEvaluationStatusCardToggled(timestamp: number|string) {
    return this.getEvalHistoryOfCurrentSet()[timestamp].isToggled;
  }

  generateHistoryEvaluationDatasource(timestamp: number|string) {
    return this.getEvalHistoryOfCurrentSet()[timestamp].evaluationResults;
  }

  getHistorySession(evalCaseResult: EvaluationResult) {
    this.addEvalCaseResultToEvents(
        evalCaseResult.sessionDetails, evalCaseResult);

    const session = this.fromApiResultToSession(evalCaseResult.sessionDetails);

    this.sessionSelected.emit(session);
  }

  protected getEvalCase(element: any) {
    this.evalService.getEvalCase(this.appName, this.selectedEvalSet, element)
        .subscribe((res) => {
          this.selectedEvalCase = res;
          this.evalCaseSelected.emit(res);
          this.evalSetIdSelected.emit(this.selectedEvalSet);
        });
  }

  deleteEvalCase(evalCaseId: string) {
    this.evalService
        .deleteEvalCase(this.appName, this.selectedEvalSet, evalCaseId)
        .subscribe((res) => {
          this.deletedEvalCaseIndex = this.evalCases.indexOf(evalCaseId);
          this.selectedEvalCase = null;
          this.listEvalCases();
        });
  }

  protected getEvaluationResult() {
    this.evalService.listEvalResults(this.appName)
        .pipe(catchError((error) => {
          if (error.status === 404 && error.statusText === 'Not Found') {
            this.shouldShowTab.emit(false);
            return of(null);
          }
          return of([]);
        }))
        .subscribe((res) => {
          for (const evalResultId of res) {
            this.evalService.getEvalResult(this.appName, evalResultId)
                .subscribe((res) => {
                  if (!this.appEvaluationResults[this.appName]) {
                    this.appEvaluationResults[this.appName] = {};
                  }

                  if (!this.appEvaluationResults[this.appName][res.evalSetId]) {
                    this.appEvaluationResults[this.appName][res.evalSetId] = {};
                  }

                  const timeStamp = res.creationTimestamp;

                  if (!this.appEvaluationResults[this.appName][res.evalSetId]
                                                [timeStamp]) {
                    this.appEvaluationResults[this.appName][res.evalSetId][timeStamp] =
                        {isToggled: false, evaluationResults: []};
                  }

                  const uiEvaluationResult: UIEvaluationResult = {
                    isToggled: false,
                    evaluationResults:
                        res.evalCaseResults.map((result: any) => {
                          return {
                            setId: result.id,
                            evalId: result.evalId,
                            finalEvalStatus: result.finalEvalStatus,
                            evalMetricResults: result.evalMetricResults,
                            evalMetricResultPerInvocation:
                                result.evalMetricResultPerInvocation,
                            sessionId: result.sessionId,
                            sessionDetails: result.sessionDetails,
                            overallEvalMetricResults:
                                result.overallEvalMetricResults ?? [],
                          };
                        }),
                  };

                  this.appEvaluationResults[this.appName][res.evalSetId][timeStamp] =
                      uiEvaluationResult;
                });
          }
        });
  }

  protected openEvalConfigDialog() {
    const dialogRef = this.dialog.open(RunEvalConfigDialogComponent, {
      maxWidth: '90vw',
      maxHeight: '90vh',
      data: {
        evalMetrics: this.evalMetrics,
      },
    });

    dialogRef.afterClosed().subscribe((evalMetrics) => {
      if (!!evalMetrics) {
        this.evalMetrics = evalMetrics;

        this.runEval();
      }
    });
  }

  protected getEvalMetrics(evalResult: any|undefined) {
    if (!evalResult || !evalResult.evaluationResults ||
        !evalResult.evaluationResults.evaluationResults) {
      return this.evalMetrics;
    }

    const results = evalResult.evaluationResults.evaluationResults;

    if (results.length === 0) {
      return this.evalMetrics;
    }

    if (typeof results[0].overallEvalMetricResults === 'undefined' ||
        !results[0].overallEvalMetricResults ||
        results[0].overallEvalMetricResults.length === 0) {
      return this.evalMetrics;
    }

    const overallEvalMetricResults = results[0].overallEvalMetricResults;

    return overallEvalMetricResults.map((result: any) => {
      return {
        metricName: result.metricName,
        threshold: result.threshold,
      };
    });
  }
}
