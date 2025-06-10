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

import { Injectable, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

export const VIEW_EVAL_CASE = 'view_eval_case';

export const SET_EVAL_CONFIG = 'set_eval_config';

@Injectable({
  providedIn: 'root'
})
export class FeatureFlagService {
  private route = inject(ActivatedRoute);

  constructor() {}

  isViewEvalCaseEnabled() {
    return this.route.snapshot.queryParams[VIEW_EVAL_CASE] === 'true';
  }

  isSetEvalConfigEnabled() {
    return this.route.snapshot.queryParams[SET_EVAL_CONFIG] === 'true';
  }
}
