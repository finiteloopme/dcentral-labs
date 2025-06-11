import { Component, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-user-registration',
  standalone: false,
  templateUrl: './user-registration.component.html',
  styleUrls: ['./user-registration.component.css']

})
export class UserRegistrationComponent {

  userReg = output<string>();

  // --- Component Properties ---

  // Model to hold the form data.
  // We can initialize the values here.
  user = {
    firstName: '',
    privateKey: '',
    riskProfile: 'Low' // Default value for the dropdown
  };

  // Array of options for the investment risk profile dropdown.
  riskProfiles: string[] = ['Low', 'Medium', 'High'];

  // --- Component Methods ---

  /**
   * Handles the form submission.
   * In a real application, this would send the data to a server.
   * For this example, we'll just log it to the console.
   */
  register(): void {
    if (!this.user.firstName || !this.user.privateKey) {
      console.error('First name and private key are required.');
      // In a real app, you'd show a user-friendly message.
      return ;
    }

    console.log('--- User Registration Data ---');
    console.log('First Name:', this.user.firstName);
    console.log('Private Key:', this.user.privateKey); // Be very careful with sensitive data like this!
    console.log('Investment Risk Profile:', this.user.riskProfile);
    var userProfile = `Use the values in the json object to register the user and then set the user profile.
    Make sure that you note the private key, which will be required for subsequent interactions.  
    But DO NOT reveal this key back to the user, use it for calling internal tools.
    {
      'firstName': '${this.user.firstName}',
      'privateKey': '${this.user.privateKey}',
      'riskProfile': '${this.user.riskProfile}',
    }`;
    this.userReg.emit(userProfile);
    return 
    // Here you would typically call a service to send this data
    // to your backend API.
    // e.g., this.authService.register(this.user).subscribe(...)
  }
}
