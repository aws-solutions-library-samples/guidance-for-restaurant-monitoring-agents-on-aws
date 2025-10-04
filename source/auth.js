// Cognito Authentication Configuration
const cognitoConfig = {
    region: 'us-east-1',
    userPoolId: 'us-east-1_h40WL9SuJ', // Replace with actual User Pool ID
    userPoolWebClientId: '3200j26lsko02f3bhhitasi7io', // Replace with actual Client ID
    identityPoolId: 'us-east-1:d4dccc68-c80b-4bba-ac22-0f62881efee3' // Replace with actual Identity Pool ID
};

// AWS Cognito SDK
const AmazonCognitoIdentity = window.AmazonCognitoIdentity;

class CognitoAuth {
    constructor() {
        this.userPool = new AmazonCognitoIdentity.CognitoUserPool({
            UserPoolId: cognitoConfig.userPoolId,
            ClientId: cognitoConfig.userPoolWebClientId
        });
        this.currentUser = null;
        this.init();
    }

    init() {
        // Check if user is already authenticated
        this.currentUser = this.userPool.getCurrentUser();
        if (this.currentUser) {
            this.currentUser.getSession((err, session) => {
                if (err) {
                    console.log('Session error:', err);
                    this.showLoginForm();
                } else if (session.isValid()) {
                    console.log('User authenticated');
                    this.showMainApp();
                } else {
                    this.showLoginForm();
                }
            });
        } else {
            this.showLoginForm();
        }
    }

    showLoginForm() {
        document.body.innerHTML = `
            <div id="auth-container">
                <div class="auth-form">
                    <h2>🏪 AnyCompany Restaurant Monitoring System</h2>
                    <div id="login-form">
                        <h3>Sign In</h3>
                        <input type="email" id="login-email" placeholder="Email" required>
                        <input type="password" id="login-password" placeholder="Password" required>
                        <button onclick="cognitoAuth.signIn()">Sign In</button>
                        <p><a href="#" onclick="cognitoAuth.showRegisterForm()">New user? Register here</a></p>
                        <p><a href="#" onclick="cognitoAuth.showForgotPassword()">Forgot password?</a></p>
                    </div>
                    <div id="register-form" style="display: none;">
                        <h3>Register</h3>
                        <input type="text" id="register-name" placeholder="Full Name" required>
                        <input type="email" id="register-email" placeholder="Email" required>
                        <input type="password" id="register-password" placeholder="Password (min 8 chars)" required>
                        <button onclick="cognitoAuth.signUp()">Register</button>
                        <p><a href="#" onclick="cognitoAuth.showLoginForm()">Already have account? Sign in</a></p>
                    </div>
                    <div id="verify-form" style="display: none;">
                        <h3>Verify Email</h3>
                        <p>Please enter the verification code sent to your email:</p>
                        <input type="text" id="verify-code" placeholder="Verification Code" required>
                        <button onclick="cognitoAuth.confirmSignUp()">Verify</button>
                    </div>
                    <div id="forgot-form" style="display: none;">
                        <h3>Reset Password</h3>
                        <input type="email" id="forgot-email" placeholder="Email" required>
                        <button onclick="cognitoAuth.forgotPassword()">Send Reset Code</button>
                        <div id="reset-form" style="display: none;">
                            <input type="text" id="reset-code" placeholder="Reset Code" required>
                            <input type="password" id="new-password" placeholder="New Password" required>
                            <button onclick="cognitoAuth.confirmPassword()">Reset Password</button>
                        </div>
                        <p><a href="#" onclick="cognitoAuth.showLoginForm()">Back to Sign In</a></p>
                    </div>
                    <div id="message"></div>
                </div>
            </div>
            <style>
                #auth-container {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    background: #f5f5f5;
                    font-family: Arial, sans-serif;
                }
                .auth-form {
                    background: white;
                    padding: 2rem;
                    border-radius: 8px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                    width: 100%;
                    max-width: 400px;
                }
                .auth-form h2 {
                    text-align: center;
                    color: #2c3e50;
                    margin-bottom: 2rem;
                }
                .auth-form h3 {
                    color: #34495e;
                    margin-bottom: 1rem;
                }
                .auth-form input {
                    width: 100%;
                    padding: 0.75rem;
                    margin: 0.5rem 0;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    box-sizing: border-box;
                }
                .auth-form button {
                    width: 100%;
                    padding: 0.75rem;
                    background: #3498db;
                    color: white;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                    margin: 0.5rem 0;
                }
                .auth-form button:hover {
                    background: #2980b9;
                }
                .auth-form a {
                    color: #3498db;
                    text-decoration: none;
                }
                .auth-form p {
                    text-align: center;
                    margin: 1rem 0;
                }
                #message {
                    margin-top: 1rem;
                    padding: 0.5rem;
                    border-radius: 4px;
                    text-align: center;
                }
                .error {
                    background: #ffebee;
                    color: #c62828;
                    border: 1px solid #ffcdd2;
                }
                .success {
                    background: #e8f5e8;
                    color: #2e7d32;
                    border: 1px solid #c8e6c9;
                }
            </style>
        `;
    }

    showRegisterForm() {
        document.getElementById('login-form').style.display = 'none';
        document.getElementById('register-form').style.display = 'block';
        document.getElementById('verify-form').style.display = 'none';
        document.getElementById('forgot-form').style.display = 'none';
    }

    showLoginForm() {
        document.getElementById('login-form').style.display = 'block';
        document.getElementById('register-form').style.display = 'none';
        document.getElementById('verify-form').style.display = 'none';
        document.getElementById('forgot-form').style.display = 'none';
    }

    showForgotPassword() {
        document.getElementById('login-form').style.display = 'none';
        document.getElementById('register-form').style.display = 'none';
        document.getElementById('verify-form').style.display = 'none';
        document.getElementById('forgot-form').style.display = 'block';
    }

    signUp() {
        const name = document.getElementById('register-name').value;
        const email = document.getElementById('register-email').value;
        const password = document.getElementById('register-password').value;

        if (!name || !email || !password) {
            this.showMessage('Please fill in all fields', 'error');
            return;
        }

        const attributeList = [
            new AmazonCognitoIdentity.CognitoUserAttribute({
                Name: 'email',
                Value: email
            }),
            new AmazonCognitoIdentity.CognitoUserAttribute({
                Name: 'name',
                Value: name
            })
        ];

        this.userPool.signUp(email, password, attributeList, null, (err, result) => {
            if (err) {
                this.showMessage(err.message, 'error');
                return;
            }
            this.pendingUser = result.user;
            this.showMessage('Registration successful! Please check your email for verification code.', 'success');
            document.getElementById('register-form').style.display = 'none';
            document.getElementById('verify-form').style.display = 'block';
        });
    }

    confirmSignUp() {
        const code = document.getElementById('verify-code').value;
        
        if (!code) {
            this.showMessage('Please enter verification code', 'error');
            return;
        }

        this.pendingUser.confirmRegistration(code, true, (err, result) => {
            if (err) {
                this.showMessage(err.message, 'error');
                return;
            }
            this.showMessage('Email verified successfully! Please sign in.', 'success');
            setTimeout(() => this.showLoginForm(), 2000);
        });
    }

    signIn() {
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;

        if (!email || !password) {
            this.showMessage('Please enter email and password', 'error');
            return;
        }

        const authenticationData = {
            Username: email,
            Password: password
        };

        const authenticationDetails = new AmazonCognitoIdentity.AuthenticationDetails(authenticationData);
        const userData = {
            Username: email,
            Pool: this.userPool
        };

        const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);

        cognitoUser.authenticateUser(authenticationDetails, {
            onSuccess: (result) => {
                console.log('Authentication successful');
                this.currentUser = cognitoUser;
                this.showMainApp();
            },
            onFailure: (err) => {
                this.showMessage(err.message, 'error');
            }
        });
    }

    forgotPassword() {
        const email = document.getElementById('forgot-email').value;
        
        if (!email) {
            this.showMessage('Please enter your email', 'error');
            return;
        }

        const userData = {
            Username: email,
            Pool: this.userPool
        };

        const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);
        
        cognitoUser.forgotPassword({
            onSuccess: () => {
                this.showMessage('Reset code sent to your email', 'success');
                document.getElementById('reset-form').style.display = 'block';
                this.resetUser = cognitoUser;
            },
            onFailure: (err) => {
                this.showMessage(err.message, 'error');
            }
        });
    }

    confirmPassword() {
        const code = document.getElementById('reset-code').value;
        const newPassword = document.getElementById('new-password').value;

        if (!code || !newPassword) {
            this.showMessage('Please enter reset code and new password', 'error');
            return;
        }

        this.resetUser.confirmPassword(code, newPassword, {
            onSuccess: () => {
                this.showMessage('Password reset successful! Please sign in.', 'success');
                setTimeout(() => this.showLoginForm(), 2000);
            },
            onFailure: (err) => {
                this.showMessage(err.message, 'error');
            }
        });
    }

    signOut() {
        if (this.currentUser) {
            this.currentUser.signOut();
            this.currentUser = null;
            this.showLoginForm();
        }
    }

    showMainApp() {
        // Load the main application
        window.location.reload();
    }

    showMessage(message, type) {
        const messageDiv = document.getElementById('message');
        messageDiv.textContent = message;
        messageDiv.className = type;
        messageDiv.style.display = 'block';
    }

    getUserInfo() {
        return new Promise((resolve, reject) => {
            if (!this.currentUser) {
                reject('No authenticated user');
                return;
            }

            this.currentUser.getSession((err, session) => {
                if (err) {
                    reject(err);
                    return;
                }

                this.currentUser.getUserAttributes((err, attributes) => {
                    if (err) {
                        reject(err);
                        return;
                    }

                    const userInfo = {};
                    attributes.forEach(attr => {
                        userInfo[attr.getName()] = attr.getValue();
                    });

                    resolve({
                        ...userInfo,
                        token: session.getIdToken().getJwtToken()
                    });
                });
            });
        });
    }
}

// CognitoAuth class available for manual initialization
// const cognitoAuth = new CognitoAuth();