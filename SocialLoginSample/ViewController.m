//
//  ViewController.m
//  SocialLoginSample
//
//  Created by tomonobu on 2014/09/09.
//  Copyright (c) 2014年 Tomonobu Sato. All rights reserved.
//

#import "ViewController.h"

#import "STTwitter.h"
#import "Accounts/Accounts.h"
#import "Social/Social.h"

static NSString *const TwitterConsumerKey = @"";
static NSString *const TwitterConsumerSecret = @"";

static NSString *const FaceBookAppID = @"";

@interface ViewController () <UIActionSheetDelegate>
@property(nonatomic) NSArray *twitterAccounts;
@property(weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *oAuthTokenLabel;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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

    __weak typeof(self) weakSelf = self;
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:NULL
                                       completion:^(BOOL granted, NSError *error) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if (granted) {
                                                   if ([accountStore accountsWithAccountType:accountType].count == 0) {
                                                       NSLog(@"Twitter account not found");
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
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                              consumerKey:TwitterConsumerKey
                                                           consumerSecret:TwitterConsumerSecret];

    [twitter postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
        STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithAccount:account];
        [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
            [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                                successBlock:^(NSString *oAuthToken,
                                                                        NSString *oAuthTokenSecret,
                                                                        NSString *userID,
                                                                        NSString *screenName) {
                                                                    NSLog(@"Token %@ secret %@ userID %@ screenName %@", oAuthToken, oAuthTokenSecret, userID, screenName);
                                                                } errorBlock:^(NSError *error) {
                        NSLog(@"postReverseAuthAccessTokenWithAuthenticationHeader error %@", error.description);
                    }];
        }                                    errorBlock:^(NSError *error) {
            NSLog(@"verifyCredentialsWithSuccessBlock erroe %@", error.description);
        }];
    }                          errorBlock:^(NSError *error) {
        NSLog(@"postReverseOAuthTokenRequest error %@", error.description);
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

    [accountStore requestAccessToAccountsWithType:accountType
                                          options:options
                                       completion:^(BOOL granted, NSError *error) {
                                           if (!granted) {
                                               NSLog(@"error: %@", error.description);
                                               return;
                                           }

                                           NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                                           ACAccount *faceBookAccount = accounts.lastObject;

                                           ACAccountCredential *facebookCredential = faceBookAccount.credential;
                                           NSString *accessToken = facebookCredential.oauthToken;

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
                                                   self.oAuthTokenLabel.text = accessToken;
                                                   self.profileImageView.image = profileImage;
                                               });
                                           }];

                                       }];
}


@end
