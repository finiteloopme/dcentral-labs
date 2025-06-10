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

import {ComponentFixture, TestBed} from '@angular/core/testing';
import {ReactiveFormsModule} from '@angular/forms';
import {MAT_DIALOG_DATA, MatDialogModule, MatDialogRef} from '@angular/material/dialog';
import {MatRadioModule} from '@angular/material/radio';
import {MatSliderModule} from '@angular/material/slider';
import {NoopAnimationsModule} from '@angular/platform-browser/animations';

import {RunEvalConfigDialogComponent} from './run-eval-config-dialog.component';

describe('RunEvalConfigDialogComponent', () => {
  let component: RunEvalConfigDialogComponent;
  let fixture: ComponentFixture<RunEvalConfigDialogComponent>;
  let dialogRefSpy: jasmine.SpyObj<MatDialogRef<RunEvalConfigDialogComponent>>;

  // Mock MatDialogRef
  const mockDialogRef = jasmine.createSpyObj('MatDialogRef', ['close']);

  beforeEach(async () => {
    await TestBed
        .configureTestingModule({
          declarations: [RunEvalConfigDialogComponent],
          imports: [
            ReactiveFormsModule, MatDialogModule, MatRadioModule,
            MatSliderModule,
            NoopAnimationsModule  // Import NoopAnimationsModule for testing
                                  // Angular Material animations
          ],
          providers: [
            {provide: MatDialogRef, useValue: mockDialogRef},
            {provide: MAT_DIALOG_DATA, useValue: {}}
            // Provide empty data for initial setup
          ]
        })
        .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(RunEvalConfigDialogComponent);
    component = fixture.componentInstance;
    dialogRefSpy = TestBed.inject(MatDialogRef) as
        jasmine.SpyObj<MatDialogRef<RunEvalConfigDialogComponent>>;
    fixture.detectChanges();  // Initialize the component and trigger change
                              // detection
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize form with default values', () => {
    expect(component.evalForm.get('metric')?.value)
        .toBe('Response match score');
    expect(component.evalForm.get('threshold')?.value).toBe(1.0);
  });

  it('should close dialog with EvalConfig object on save', () => {
    // Set form values
    component.evalForm.controls['metric'].setValue('Tool trajectory avg score');
    component.evalForm.controls['threshold'].setValue(0.5);

    component.onSave();

    // Expect dialogRef.close to have been called with the correct EvalConfig
    // object
    expect(dialogRefSpy.close)
        .toHaveBeenCalledWith(new EvalConfig('Tool trajectory avg score', 0.5));
  });

  it('should close dialog with null on cancel', () => {
    component.onCancel();
    expect(dialogRefSpy.close).toHaveBeenCalledWith(null);
  });

  it('should disable save button if form is invalid (e.g., metric not selected)',
     () => {
       component.evalForm.controls['metric'].setValue(
           '');                  // Set metric to invalid state (empty)
       fixture.detectChanges();  // Trigger change detection

       // Check if the form is indeed invalid
       expect(component.evalForm.invalid).toBeTrue();

       // Query the save button and check its disabled property
       const saveButton: HTMLButtonElement =
           fixture.nativeElement.querySelector('.save-button');
       expect(saveButton.disabled).toBeTrue();
     });

  it('should show error message for invalid threshold (less than 0)', () => {
    component.evalForm.controls['threshold'].setValue(-0.1);
    component.evalForm.controls['threshold']
        .markAsTouched();  // Mark as touched to show errors
    fixture.detectChanges();

    const errorMessage = fixture.nativeElement.querySelector('.error-message');
    expect(errorMessage).toBeTruthy();
    expect(errorMessage.textContent).toContain('Threshold must be at least 0');
  });

  it('should show error message for invalid threshold (greater than 1)', () => {
    component.evalForm.controls['threshold'].setValue(1.1);
    component.evalForm.controls['threshold'].markAsTouched();
    fixture.detectChanges();

    const errorMessage = fixture.nativeElement.querySelector('.error-message');
    expect(errorMessage).toBeTruthy();
    expect(errorMessage.textContent).toContain('Threshold cannot exceed 1');
  });

  // --- Additional Tests Below ---

  it('should initialize form with injected data', async () => {
    // Reconfigure TestBed to provide initial data
    TestBed.overrideProvider(MAT_DIALOG_DATA, {
      useValue:
          {initialMetric: 'Tool trajectory avg score', initialThreshold: 0.75}
    });

    // Recreate the component with the new data
    fixture = TestBed.createComponent(RunEvalConfigDialogComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();  // Initialize the component

    expect(component.evalForm.get('metric')?.value)
        .toBe('Tool trajectory avg score');
    expect(component.evalForm.get('threshold')?.value).toBe(0.75);
  });

  it('should enable save button when form is valid', () => {
    // Ensure form is valid by setting values if defaults aren't enough (they
    // are here)
    component.evalForm.controls['metric'].setValue('Response match score');
    component.evalForm.controls['threshold'].setValue(0.5);
    fixture.detectChanges();

    expect(component.evalForm.valid).toBeTrue();
    const saveButton: HTMLButtonElement =
        fixture.nativeElement.querySelector('.save-button');
    expect(saveButton.disabled).toBeFalse();
  });

  it('should update threshold value when slider changes (simulated)', () => {
    const slider = component.evalForm.controls['threshold'];
    slider.setValue(0.3);  // Simulate slider value change
    fixture.detectChanges();

    expect(slider.value).toBe(0.3);
    const thresholdValueDisplay: HTMLElement =
        fixture.nativeElement.querySelector('.threshold-value');
    expect(thresholdValueDisplay.textContent).toContain('0.3');
  });

  it('should reset form state after dialog close (if component re-created)',
     () => {
       // This tests the component's initial state upon creation, effectively
       // testing a reset. Set some values and then expect them to be default
       // again on new creation.
       component.evalForm.controls['metric'].setValue(
           'Tool trajectory avg score');
       component.evalForm.controls['threshold'].setValue(0.1);
       fixture.detectChanges();

       // Simulate closing and re-opening by destroying and recreating the
       // component
       fixture.destroy();
       fixture = TestBed.createComponent(RunEvalConfigDialogComponent);
       component = fixture.componentInstance;
       fixture.detectChanges();

       expect(component.evalForm.get('metric')?.value)
           .toBe('Response match score');
       expect(component.evalForm.get('threshold')?.value).toBe(1.0);
     });

  it('should show required error message for metric if not selected', () => {
    component.evalForm.controls['metric'].setValue('');  // Unselect metric
    component.evalForm.controls['metric']
        .markAsTouched();  // Trigger validation
    fixture.detectChanges();

    const errorMessage = fixture.nativeElement.querySelector('.error-message');
    expect(errorMessage).toBeTruthy();
    expect(errorMessage.textContent).toContain('You must select a metric');
  });
});
