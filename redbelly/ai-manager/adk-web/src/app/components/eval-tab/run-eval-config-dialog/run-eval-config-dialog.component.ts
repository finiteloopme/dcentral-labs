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

import {Component, Inject} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';
import {MAT_DIALOG_DATA, MatDialogRef} from '@angular/material/dialog';

/**
 * @interface EvalMetric
 * @description Represents a single evaluation metric and its associated
 * threshold.
 */
export interface EvalMetric {
  metricName: string;
  threshold: number;
}

/**
 * @interface EvalConfigData
 * @description Data injected into the dialog, including the list of available
 * evaluation metrics.
 */
export interface EvalConfigData {
  evalMetrics: EvalMetric[];
}

@Component({
  selector: 'app-run-eval-config-dialog',
  templateUrl: './run-eval-config-dialog.component.html',
  styleUrls: ['./run-eval-config-dialog.component.scss'],
  standalone: false,
})
export class RunEvalConfigDialogComponent {
  // FormGroup to manage the dialog's form controls
  evalForm: FormGroup;

  // Available evaluation metrics, matching the image
  metrics: string[] = ['Tool trajectory avg score', 'Response match score'];

  /**
   * @constructor
   * @param {MatDialogRef<RunEvalConfigDialogComponent>} dialogRef - Reference
   *     to the dialog opened.
   * @param {FormBuilder} fb - Angular's FormBuilder for creating reactive
   *     forms.
   * @param {EvalConfigData} data - Data injected into the dialog (e.g., initial
   *     values).
   */
  constructor(
      public dialogRef: MatDialogRef<RunEvalConfigDialogComponent>,
      private fb: FormBuilder,
      @Inject(MAT_DIALOG_DATA) public data: EvalConfigData) {
    // Initialize the form with controls and validators
    this.evalForm = this.fb.group({
      tool_trajectory_avg_score_threshold: [
        this.getEvalMetricThresholdFromData('tool_trajectory_avg_score'),
        [Validators.required, Validators.min(0), Validators.max(1)]
      ],
      response_match_score_threshold: [
        this.getEvalMetricThresholdFromData('response_match_score'),
        [Validators.required, Validators.min(0), Validators.max(1)]
      ]
    });
  }

  private getEvalMetricThresholdFromData(metricName: string): number {
    return this.data.evalMetrics
               .find((metric) => metric.metricName === metricName)
               ?.threshold ??
        0;
  }

  onStart(): void {
    if (this.evalForm.valid) {
      const {
        tool_trajectory_avg_score_threshold,
        response_match_score_threshold
      } = this.evalForm.value;

      const evalMetrics: EvalMetric[] = [
        {
          metricName: 'tool_trajectory_avg_score',
          threshold: tool_trajectory_avg_score_threshold,
        },
        {
          metricName: 'response_match_score',
          threshold: response_match_score_threshold,
        }
      ];

      this.dialogRef.close(evalMetrics);
    }
  }

  onCancel(): void {
    this.dialogRef.close(
        null);  // Return null or undefined to indicate cancellation
  }
}