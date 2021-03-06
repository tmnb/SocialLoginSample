//
//  ViewController.m
//  SocialLoginSample
//
//  Created by tomonobu on 2014/09/09.
//  Copyright (c) 2014年 Tomonobu Sato. All rights reserved.
//

#import "ViewController.h"

#import "Accounts/Accounts.h"
#import "Social/Social.h"

#import "STTwitter.h"
#import "FacebookSDK.h"

static NSString *const TwitterConsumerKey = @"";
static NSString *const TwitterConsumerSecret = @"";

static NSString *const FaceBookAppID = @"";

@interface ViewController () <UIActionSheetDelegate>
@property (nonatomic) STTwitterAPI *twitterAPI;
@property(nonatomic) NSArray *twitterAccounts;
@property(weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *oAuthTokenLabel;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)twitterLoginButtonTapped:(id)sender
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    self.twitterAPI = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                        consumerKey:TwitterConsumerKey
                                                     consumerSecret:TwitterConsumerSecret];

    __weak typeof(self) weakSelf = self;
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:NULL
                                       completion:^(BOOL granted, NSError *error) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if (granted) {
                                                   if ([accountStore accountsWithAccountType:accountType].count == 0) {
                                                       NSLog(@"Twitter account not found");

                                                       [_twitterAPI postTokenRequest:^(NSURL *url, NSString *oauthToken) {
                                                           [[UIApplication sharedApplication] openURL:url];
                                                       } authenticateInsteadOfAuthorize:NO
                                                               forceLogin:@(YES)
                                                               screenName:nil
                                                               oauthCallback:@"socialloginsample://twitter_social"
                                                               errorBlock:^(NSError *error) {
                                                                   NSLog(@"error %@", error.description);
                                                               }];
                                                       return;
                                                   }

                                                   if ([accountStore accountsWithAccountType:accountType].count > 1) {
                                                       UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                                                                delegate:weakSelf
                                                                                                       cancelButtonTitle:nil
                                                                                                  destructiveButtonTitle:nil
                                                                                                       otherButtonTitles:nil, nil];

                                                       self.twitterAccounts = [accountStore accountsWithAccountType:accountType];
                                                       for (ACAccount *account in _twitterAccounts) {
                                                           [actionSheet addButtonWithTitle:account.username];
                                                       }

                                                       [actionSheet showInView:self.view];

                                                   } else {
                                                       ACAccount *account = [accountStore accountsWithAccountType:accountType].lastObject;
                                                       [self requestTwitterAuthAccessTokenWithAccount:account];
                                                   }
                                               } else {
                                                   NSLog(@"error %@", error.description);
                                               }
                                           });
                                       }];

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    ACAccount *account = _twitterAccounts[buttonIndex];

    [self requestTwitterAuthAccessTokenWithAccount:account];
}

- (void)requestTwitterAuthAccessTokenWithAccount:(ACAccount *)account
{
    [_twitterAPI postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
        STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithAccount:account];
        [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
            [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                                successBlock:^(NSString *oAuthToken,
                                                                        NSString *oAuthTokenSecret,
                                                                        NSString *userID,
                                                                        NSString *screenName) {

                                                                    NSLog(@"Token %@ secret %@ userID %@ screenName %@", oAuthToken, oAuthTokenSecret, userID, screenName);

                                                                    [_twitterAPI profileImageFor:screenName successBlock:^(id image) {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            self.oAuthTokenLabel.text = oAuthToken;
                                                                            self.profileImageView.image = image;
                                                                        });
                                                                    } errorBlock:^(NSError *error) {
                                                                        NSLog(@"error %@", error.description);
                                                                    }];


                                                                } errorBlock:^(NSError *error) {
                                                                    NSLog(@"postReverseAuthAccessTokenWithAuthenticationHeader error %@", error.description);
                                                                }];
        } errorBlock:^(NSError *error) {
            NSLog(@"verifyCredentialsWithSuccessBlock erroe %@", error.description);
        }];
    } errorBlock:^(NSError *error) {
        NSLog(@"postReverseOAuthTokenRequest error %@", error.description);
    }];
}

- (void)setOAuthToken:(NSString *)token oauthVerifier:(NSString *)verifier
{
    [_twitterAPI postAccessTokenRequestWithPIN:verifier
                                  successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
                                      NSLog(@"Token %@ secret %@ userID %@ screenName %@", oauthToken, oauthTokenSecret, userID, screenName);
                                  } errorBlock:^(NSError *error) {
                                      NSLog(@"error %@", error.description);
                                  }];
}

- (IBAction)facebookLoginButtonTapped:(id)sender
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

    NSDictionary *options = @{
        ACFacebookAppIdKey : FaceBookAppID,
        ACFacebookPermissionsKey : @[@"email"]
    };

    __weak typeof(self) weakSelf = self;

    [accountStore requestAccessToAccountsWithType:accountType
                                          options:options
                                       completion:^(BOOL granted, NSError *error) {
                                           if (!granted) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [weakSelf facebookLogin];
                                               });
                                               NSLog(@"error: %@", error.description);
                                               return;
                                           }

                                           NSArray *accounts = [accountStore accountsWithAccountType:accountType];

                                           if (!accounts.count) {
                                               NSLog(@"facebook account not found");
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [self facebookLogin];
                                               });
                                               return;
                                           }

                                           ACAccount *faceBookAccount = accounts.lastObject;

                                           SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                                                   requestMethod:SLRequestMethodGET
                                                                                             URL:[[NSURL alloc] initWithString:@"https://graph.facebook.com/me/picture"]
                                                                                      parameters:@{@"type":@"large"}];
                                           request.account = faceBookAccount;
                                           [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                               if (error) {
                                                   NSLog(@"error: %@", error.description);
                                                   return;
                                               }
                                               UIImage *profileImage = [[UIImage alloc] initWithData:responseData];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   self.oAuthTokenLabel.text = faceBookAccount.credential.oauthToken;
                                                   self.profileImageView.image = profileImage;
                                               });
                                           }];

                                       }];
}

- (void)facebookLogin
{
    if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    else {

            [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email"]
                                               allowLoginUI:YES
                                          completionHandler:
                                                  ^(FBSession *session, FBSessionState state, NSError *error) {
                                                      [self sessionStateChanged:session state:state error:error];
                                                  }];
    }
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    if (!error && state == FBSessionStateOpen){
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            NSLog(@"%@", [FBSession activeSession].accessTokenData.accessToken);
            NSLog(@"%@", result);
            NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", result[@"id"]];
            NSLog(@"%@", userImageURL);
        }];

        return;
    }

    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        NSLog(@"Session closed");
        [FBSession.activeSession closeAndClearTokenInformation];
    }

    if (error){
        NSLog(@"Error");
        if ([FBErrorUtility shouldNotifyUserForError:error]){
            NSLog(@"%@", [FBErrorUtility userMessageForError:error]);
        }
        else {
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
            }
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                NSLog(@"%@", [FBErrorUtility userMessageForError:error]);
            }
            else {
                NSDictionary *errorInformation = (error.userInfo)[@"com.facebook.sdk:ParsedJSONResponseKey"][@"body"][@"error"];
                NSLog(@"%@", errorInformation[@"message"]);
            }
        }
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}

@end
