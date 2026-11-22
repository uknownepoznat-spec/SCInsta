#import "SCILicenseViewController.h"
#import "SCILicenseManager.h"
#import "SCILicenseConfig.h"
#import "../Appearance/SCITheme.h"
#import "../Utils.h"

@interface SCILicenseViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *accessLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *deviceLabel;
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) UIButton *forgetButton;
@end

@implementation SCILicenseViewController
- (UILabel *)label:(NSString *)text style:(UIFontTextStyle)style {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:style];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = SCITheme.textColor;
    label.numberOfLines = 0;
    return label;
}
- (UIButton *)button:(NSString *)title action:(SEL)action prominent:(BOOL)prominent {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = prominent ? UIButtonConfiguration.filledButtonConfiguration : UIButtonConfiguration.tintedButtonConfiguration;
    configuration.title = title;
    configuration.baseBackgroundColor = SCITheme.accentColor;
    configuration.baseForegroundColor = prominent ? SCITheme.backgroundColor : SCITheme.textColor;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(14, 16, 14, 16);
    configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    button.configuration = configuration;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"License & device";
    self.overrideUserInterfaceStyle = SCITheme.interfaceStyle;
    self.view.backgroundColor = SCITheme.backgroundColor;
    self.modalInPresentation = YES;
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:scroll];
    UILabel *title = [self label:@"Peki Scripter" style:UIFontTextStyleLargeTitle];
    UILabel *detail = [self label:@"A valid license is required to open this custom build.\nNever enter your Instagram password here." style:UIFontTextStyleSubheadline];
    detail.textColor = SCITheme.secondaryTextColor;
    self.accessLabel = [self label:@"No access — Buy a key" style:UIFontTextStyleTitle2];
    self.statusLabel = [self label:@"" style:UIFontTextStyleBody];
    self.keyField = [UITextField new];
    self.keyField.placeholder = @"License key";
    self.keyField.accessibilityLabel = @"Peki Scripter license key";
    self.keyField.secureTextEntry = YES;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.keyboardType = UIKeyboardTypeASCIICapable;
    self.keyField.returnKeyType = UIReturnKeyGo;
    self.keyField.borderStyle = UITextBorderStyleRoundedRect;
    self.keyField.backgroundColor = SCITheme.surfaceColor;
    self.keyField.textColor = SCITheme.cellTextColor;
    self.keyField.delegate = self;
    [self.keyField.heightAnchor constraintGreaterThanOrEqualToConstant:50].active = YES;
    self.loginButton = [self button:@"Activate access" action:@selector(login:) prominent:YES];
    self.retryButton = [self button:@"Retry saved license" action:@selector(retry:) prominent:NO];
    UILabel *deviceTitle = [self label:@"Device code" style:UIFontTextStyleHeadline];
    self.deviceLabel = [self label:@"Preparing device key…" style:UIFontTextStyleFootnote];
    self.deviceLabel.font = [[UIFontMetrics defaultMetrics] scaledFontForFont:[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular]];
    self.deviceLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.deviceLabel.textColor = SCITheme.secondaryTextColor;
    UIButton *copy = [self button:@"Copy device code" action:@selector(copyDevice:) prominent:NO];
    UIButton *support = [self button:@"No key? Buy access / Discord" action:@selector(support:) prominent:NO];
    UILabel *contact = [self label:[NSString stringWithFormat:@"Discord: %@", SCILicenseConfig.supportUsername]
        style:UIFontTextStyleFootnote];
    contact.textColor = SCITheme.secondaryTextColor;
    self.forgetButton = [self button:@"Forget saved license" action:@selector(forget:) prominent:NO];
    UIButton *diagnostics = [self button:@"Copy compatibility report" action:@selector(diagnostics:) prominent:NO];
    UILabel *notice = [self label:@"Device code is a public-key fingerprint, not an IMEI or iPhone serial number. A reset, signing/access-group change or lost key may require a new approval." style:UIFontTextStyleFootnote];
    notice.textColor = SCITheme.secondaryTextColor;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        title, detail, self.accessLabel, self.statusLabel, self.keyField, self.loginButton, self.retryButton,
        deviceTitle, self.deviceLabel, copy, support, contact, self.forgetButton, diagnostics, notice
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-24],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:28],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-28],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-48]
    ]];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(stateChanged:)
        name:SCILicenseStateDidChangeNotification object:nil];
    [self stateChanged:nil];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)stateChanged:(NSNotification *)notification {
    SCILicenseManager *manager = SCILicenseManager.sharedManager;
    self.accessLabel.text = manager.authorized ? @"Access active"
        : manager.busy ? @"Checking access…" : @"No access — Buy a key";
    self.statusLabel.text = manager.message;
    self.deviceLabel.text = manager.deviceID.length ? manager.deviceID : @"Device key unavailable or still loading.";
    self.keyField.enabled = !manager.busy && !manager.authorized;
    self.loginButton.enabled = !manager.busy && !manager.authorized && manager.deviceID.length && SCILicenseConfig.baseURL;
    self.retryButton.enabled = !manager.busy;
    self.forgetButton.enabled = !manager.busy;
    if (manager.authorized) self.keyField.text = @"";
}
- (void)login:(id)sender {
    [self.keyField resignFirstResponder];
    NSString *key = self.keyField.text;
    self.keyField.text = @""; // Do not leave the credential visible in view state.
    [SCILicenseManager.sharedManager submitLicense:key];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [self login:nil]; return YES; }
- (void)retry:(id)sender { [SCILicenseManager.sharedManager retry]; }
- (void)copyDevice:(id)sender {
    NSString *code = SCILicenseManager.sharedManager.deviceID;
    if (code.length) UIPasteboard.generalPasteboard.string = code;
}
- (void)diagnostics:(id)sender {
    UIPasteboard.generalPasteboard.string = [NSString stringWithFormat:@"%@\nLicense gate: %@\nDevice code: %@",
        [SCIUtils compatibilityReport], SCILicenseManager.sharedManager.message, SCILicenseManager.sharedManager.deviceID ?: @"unavailable"];
}
- (void)support:(id)sender {
    NSURL *url = SCILicenseManager.sharedManager.supportURL;
    if (url) {
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        return;
    }
    UIPasteboard.generalPasteboard.string = SCILicenseConfig.supportUsername;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Discord username copied"
        message:[NSString stringWithFormat:@"Contact %@. The developer has not configured a direct purchase/Discord link yet.", SCILicenseConfig.supportUsername]
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Open Discord" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://discord.com"] options:@{} completionHandler:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)forget:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Forget this license?"
        message:@"Access will lock. Your device key and KeyAux activation are not deleted or reset."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Forget" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [SCILicenseManager.sharedManager forgetLicense];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
