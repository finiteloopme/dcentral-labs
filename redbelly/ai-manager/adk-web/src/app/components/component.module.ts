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

import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule} from '@angular/material/button';
import {MatButtonToggleModule} from '@angular/material/button-toggle';
import {MatCardModule} from '@angular/material/card';
import {MatCheckboxModule} from '@angular/material/checkbox';
import {MatChipsModule} from '@angular/material/chips';
import {MatDialogActions, MatDialogClose, MatDialogContent, MatDialogModule, MatDialogTitle} from '@angular/material/dialog';
import {MatFormFieldModule} from '@angular/material/form-field';
import {MatIconModule} from '@angular/material/icon';
import {MatInputModule} from '@angular/material/input';
import {MatListModule} from '@angular/material/list';
import {MatPaginatorModule} from '@angular/material/paginator';
import {MatProgressBarModule} from '@angular/material/progress-bar';
import {MatProgressSpinnerModule} from '@angular/material/progress-spinner';
import {MatRadioModule} from '@angular/material/radio';
import {MatExpansionModule} from '@angular/material/expansion';
import {MatSelectModule} from '@angular/material/select';
import {MatSidenavModule} from '@angular/material/sidenav';
import {MatSlideToggleModule} from '@angular/material/slide-toggle';
import {MatSliderModule} from '@angular/material/slider';
import {MatTableModule} from '@angular/material/table';
import {MatTabsModule} from '@angular/material/tabs';
import {MatTooltipModule} from '@angular/material/tooltip';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {NgxJsonViewerModule} from 'ngx-json-viewer';
import {MarkdownModule} from 'ngx-markdown';

import {ResizableDrawerDirective} from '../directives/resizable-drawer.directive';

import {ArtifactTabComponent} from './artifact-tab/artifact-tab.component';
import {AudioPlayerComponent} from './audio-player/audio-player.component';
import {ChatComponent} from './chat/chat.component';
import {UserRegistrationComponent} from './user-rego/user-registration.component';
import {AddEvalSessionDialogComponent} from './eval-tab/add-eval-session-dialog/add-eval-session-dialog/add-eval-session-dialog.component';
import {EvalTabComponent} from './eval-tab/eval-tab.component';
import {NewEvalSetDialogComponentComponent} from './eval-tab/new-eval-set-dialog/new-eval-set-dialog-component/new-eval-set-dialog-component.component';
import {RunEvalConfigDialogComponent} from './eval-tab/run-eval-config-dialog/run-eval-config-dialog.component';
import {EventTabComponent} from './event-tab/event-tab.component';
import {TraceChartComponent} from './event-tab/trace-chart/trace-chart.component';
import {PendingEventDialogComponent} from './pending-event-dialog/pending-event-dialog.component';
import {DeleteSessionDialogComponent} from './session-tab/delete-session-dialog/delete-session-dialog.component';
import {SessionTabComponent} from './session-tab/session-tab.component';
import {StateTabComponent} from './state-tab/state-tab.component';
import {ViewImageDialogComponent} from './view-image-dialog/view-image-dialog.component';
import { TraceTabComponent } from './trace-tab/trace-tab.component';
import { TraceTreeComponent } from './trace-tab/trace-tree/trace-tree.component';

const COMPONENTS = [
  ChatComponent,
  UserRegistrationComponent,
  PendingEventDialogComponent,
  EventTabComponent,
  SessionTabComponent,
  EvalTabComponent,
  NewEvalSetDialogComponentComponent,
  AddEvalSessionDialogComponent,
  ArtifactTabComponent,
  DeleteSessionDialogComponent,
  StateTabComponent,
  TraceChartComponent,
  ViewImageDialogComponent,
  RunEvalConfigDialogComponent,
  AudioPlayerComponent,
  ResizableDrawerDirective,
  TraceTabComponent,
  TraceTreeComponent
];

@NgModule({
  declarations: [...COMPONENTS],
  exports: [...COMPONENTS],
  imports: [
    CommonModule,
    FormsModule,
    MatCardModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatDialogTitle,
    MatPaginatorModule,
    MatDialogContent,
    MatDialogActions,
    MatDialogClose,
    MatListModule,
    NgxJsonViewerModule,
    MatSidenavModule,
    MatTabsModule,
    MatRadioModule,
    MatSelectModule,
    MatSliderModule,
    MatCheckboxModule,
    MatTableModule,
    MatExpansionModule,
    MatTooltipModule,
    MatProgressBarModule,
    BrowserAnimationsModule,
    MatProgressSpinnerModule,
    MarkdownModule.forRoot(),
    MatSlideToggleModule,
    ReactiveFormsModule,
    MatChipsModule,
    MatDialogModule,
    MatButtonToggleModule
  ],
})
export class ComponentModule {
}
