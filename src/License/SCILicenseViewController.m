#import "SCILicenseViewController.h"
#import "SCILicenseManager.h"
#import "SCILicenseConfig.h"
#import "../Appearance/SCIBrandMarkView.h"
#import <QuartzCore/QuartzCore.h>

static UIColor *SCILicenseActionColor(void) {
    return [UIColor colorWithWhite:0.11 alpha:1];
}
static UIColor *SCILicenseAccentColor(void) {
    return UIColor.whiteColor;
}

@interface SCILicenseViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation SCILicenseViewController
- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }
- (UIButton *)link:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline]
        scaledFontForFont:[UIFont systemFontOfSize:14 weight:UIFontWeightMedium]];
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Peki Scripter V2";
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.backgroundColor = UIColor.blackColor;
    self.modalInPresentation = YES;

    UIScrollView *scroll = [UIScrollView new];
    self.scrollView = scroll;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:scroll];
    UIView *content = [UIView new];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    UIView *markContainer = [UIView new];
    [markContainer.heightAnchor constraintEqualToConstant:64].active = YES;
    SCIBrandMarkView *mark = [SCIBrandMarkView new];
    mark.tintColor = SCILicenseAccentColor();
    mark.translatesAutoresizingMaskIntoConstraints = NO;
    [markContainer addSubview:mark];
    [NSLayoutConstraint activateConstraints:@[
        [mark.widthAnchor constraintEqualToConstant:56],
        [mark.heightAnchor constraintEqualToConstant:56],
        [mark.centerXAnchor constraintEqualToAnchor:markContainer.centerXAnchor],
        [mark.centerYAnchor constraintEqualToAnchor:markContainer.centerYAnchor]
    ]];
    UILabel *title = [UILabel new];
    title.text = @"Peki Scripter V2";
    title.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle1]
        scaledFontForFont:[UIFont systemFontOfSize:28 weight:UIFontWeightSemibold]];
    title.adjustsFontForContentSizeCategory = YES;
    title.textColor = UIColor.whiteColor;
    title.textAlignment = NSTextAlignmentCenter;
    title.numberOfLines = 0;
    UIButton *instagram = [self link:@"@pekifn" action:@selector(instagram:)];

    self.keyField = [UITextField new];
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter your licence"
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.62 alpha:1]}];
    self.keyField.accessibilityLabel = @"Enter your licence";
    self.keyField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.keyField.adjustsFontForContentSizeCategory = YES;
    self.keyField.secureTextEntry = YES;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.keyField.smartQuotesType = UITextSmartQuotesTypeNo;
    self.keyField.smartDashesType = UITextSmartDashesTypeNo;
    self.keyField.keyboardType = UIKeyboardTypeASCIICapable;
    self.keyField.returnKeyType = UIReturnKeyGo;
    self.keyField.enablesReturnKeyAutomatically = YES;
    self.keyField.backgroundColor = [UIColor colorWithWhite:0.055 alpha:1];
    self.keyField.textColor = UIColor.whiteColor;
    self.keyField.tintColor = SCILicenseAccentColor();
    self.keyField.layer.cornerRadius = 12;
    self.keyField.layer.borderWidth = 1;
    self.keyField.layer.borderColor = [UIColor colorWithWhite:0.40 alpha:1].CGColor;
    self.keyField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.keyField.leftViewMode = UITextFieldViewModeAlways;
    self.keyField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.keyField.rightViewMode = UITextFieldViewModeAlways;
    self.keyField.delegate = self;
    [self.keyField.heightAnchor constraintGreaterThanOrEqualToConstant:56].active = YES;

    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = UIButtonConfiguration.filledButtonConfiguration;
    configuration.title = @"Activate";
    configuration.baseBackgroundColor = SCILicenseActionColor();
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleFixed;
    configuration.background.cornerRadius = 12;
    configuration.background.strokeWidth = 1;
    configuration.background.strokeColor = [UIColor colorWithWhite:0.50 alpha:1];
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(16, 20, 16, 20);
    self.loginButton.configuration = configuration;
    self.loginButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    [self.loginButton.heightAnchor constraintGreaterThanOrEqualToConstant:54].active = YES;
    [self.loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.adjustsFontForContentSizeCategory = YES;
    self.statusLabel.textColor = UIColor.whiteColor;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.hidden = YES;

    UIView *formGap = [UIView new];
    [formGap.heightAnchor constraintEqualToConstant:8].active = YES;
    UIView *contactGap = [UIView new];
    [contactGap.heightAnchor constraintEqualToConstant:12].active = YES;
    UIButton *discord = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *discordStyle = UIButtonConfiguration.filledButtonConfiguration;
    discordStyle.title = @"Join Discord";
    discordStyle.baseBackgroundColor = [UIColor colorWithWhite:0.055 alpha:1];
    discordStyle.baseForegroundColor = SCILicenseAccentColor();
    discordStyle.cornerStyle = UIButtonConfigurationCornerStyleFixed;
    discordStyle.background.cornerRadius = 12;
    discordStyle.background.strokeWidth = 1;
    discordStyle.background.strokeColor = [UIColor colorWithWhite:0.40 alpha:1];
    discordStyle.contentInsets = NSDirectionalEdgeInsetsMake(14, 20, 14, 20);
    discord.configuration = discordStyle;
    discord.titleLabel.adjustsFontForContentSizeCategory = YES;
    [discord.heightAnchor constraintGreaterThanOrEqualToConstant:50].active = YES;
    [discord addTarget:self action:@selector(discord:) forControlEvents:UIControlEventTouchUpInside];
    UIButton *tiktok = [self link:@"TikTok: @peki_scripter" action:@selector(tiktok:)];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        markContainer, title, instagram, formGap, self.keyField, self.loginButton,
        self.statusLabel, contactGap, discord, tiktok
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:stack];
    NSLayoutConstraint *contentHeight = [content.heightAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.heightAnchor];
    contentHeight.priority = UILayoutPriorityDefaultLow;
    NSLayoutConstraint *formWidth = [stack.widthAnchor constraintEqualToAnchor:content.widthAnchor constant:-48];
    formWidth.priority = UILayoutPriorityDefaultHigh;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],
        [content.heightAnchor constraintGreaterThanOrEqualToAnchor:scroll.frameLayoutGuide.heightAnchor],
        contentHeight, formWidth,
        [stack.widthAnchor constraintLessThanOrEqualToConstant:380],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:content.leadingAnchor constant:24],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:content.trailingAnchor constant:-24],
        [stack.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
        [stack.topAnchor constraintGreaterThanOrEqualToAnchor:content.topAnchor constant:24],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:content.bottomAnchor constant:-24]
    ]];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(stateChanged:)
        name:SCILicenseStateDidChangeNotification object:nil];
    [self stateChanged:nil];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.keyField.isFirstResponder) {
        CGRect field = [self.keyField convertRect:CGRectInset(self.keyField.bounds, 0, -8) toView:self.scrollView];
        [self.scrollView scrollRectToVisible:field animated:NO];
    }
}
- (void)stateChanged:(NSNotification *)notification {
    SCILicenseManager *manager = SCILicenseManager.sharedManager;
    self.statusLabel.text = manager.errorMessage;
    self.statusLabel.hidden = !manager.errorMessage.length || manager.busy;
    self.keyField.hidden = manager.authorized;
    self.keyField.enabled = !manager.busy && !manager.authorized;
    self.loginButton.enabled = !manager.busy && !manager.authorized;
    UIButtonConfiguration *configuration = self.loginButton.configuration;
    configuration.title = manager.authorized ? @"Active" : @"Activate";
    configuration.showsActivityIndicator = manager.busy;
    self.loginButton.configuration = configuration;
    if (manager.authorized) self.keyField.text = @"";
}
- (void)login:(id)sender {
    SCILicenseManager *manager = SCILicenseManager.sharedManager;
    if (manager.busy || manager.authorized) return;
    [self.keyField resignFirstResponder];
    NSString *key = self.keyField.text;
    self.keyField.text = @"";
    if (!manager.deviceID.length) {
        [manager retry];
        return;
    }
    [manager submitLicense:key];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [self login:nil]; return YES; }
- (void)instagram:(id)sender {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.instagram.com/pekifn/"]
        options:@{} completionHandler:nil];
}
- (void)discord:(id)sender {
    [UIApplication.sharedApplication openURL:SCILicenseConfig.supportURL options:@{} completionHandler:nil];
}
- (void)tiktok:(id)sender {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.tiktok.com/@peki_scripter"]
        options:@{} completionHandler:nil];
}
@end
