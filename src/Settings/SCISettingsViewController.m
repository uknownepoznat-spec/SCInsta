#import "SCISettingsViewController.h"

static char rowStaticRef[] = "row";

static UIColor *SCISettingsBackground(void) {
    return [UIColor colorWithRed:0.035 green:0.047 blue:0.071 alpha:1];
}

static UIColor *SCISettingsSurface(void) {
    return [UIColor colorWithRed:0.067 green:0.082 blue:0.114 alpha:1];
}

static UILabel *SCISettingsLabel(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color) {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [[UIFontMetrics defaultMetrics] scaledFontForFont:[UIFont systemFontOfSize:size weight:weight]];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;

@end

///

@implementation SCISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    
    if (self) {
        self.title = title;
        self.reduceMargin = reduceMargin;
        
        // Exclude development cells from release builds
        NSMutableArray *mutableSections = [sections mutableCopy];
        
        [mutableSections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *section, NSUInteger index, BOOL *stop) {
        
            if ([section[@"header"] hasPrefix:@"_"] && [section[@"footer"] hasPrefix:@"_"]) {
                if (![[SCIUtils IGVersionString] isEqualToString:@"0.0.0"]) {
                    [mutableSections removeObjectAtIndex:index];
                }
            }
            
        }];
        
        self.sections = [mutableSections copy];
    }
    
    
    return self;
}

- (instancetype)init {
    return [self initWithTitle:[SCITweakSettings title] sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    // Minimal, premium settings styling: one solid accent and no rainbow gradients.
    UINavigationBarAppearance *navigationAppearance = [UINavigationBarAppearance new];
    [navigationAppearance configureWithOpaqueBackground];
    navigationAppearance.backgroundColor = SCISettingsBackground();
    navigationAppearance.shadowColor = UIColor.clearColor;
    navigationAppearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor labelColor],
        NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]
    };
    self.navigationController.navigationBar.standardAppearance = navigationAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navigationAppearance;
    self.navigationController.navigationBar.compactAppearance = navigationAppearance;
    self.navigationController.navigationBar.tintColor = [SCIUtils SCIColor_Primary];
    self.view.backgroundColor = SCISettingsBackground();
    if (self.reduceMargin) {
        self.navigationItem.title = @"CONTROL CENTER";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings:)];
    }

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 24, 0);
    self.tableView.delegate = self;
    self.tableView.backgroundColor = SCISettingsBackground();
    self.tableView.tintColor = [SCIUtils SCIColor_Primary];
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.06];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 76;
    self.tableView.sectionHeaderTopPadding = 16;

    [self.view addSubview:self.tableView];
    if (self.reduceMargin) [self buildDashboardHeader];
}

- (void)closeSettings:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)buildDashboardHeader {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 240)];
    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = SCISettingsSurface();
    card.layer.cornerRadius = 24;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [UIColor colorWithRed:0.16 green:0.23 blue:0.36 alpha:1].CGColor;
    [header addSubview:card];

    UILabel *badge = SCISettingsLabel(@"  PS / INSTAGRAM", 11, UIFontWeightBold, [UIColor colorWithRed:0.50 green:0.69 blue:1 alpha:1]);
    UILabel *title = SCISettingsLabel(@"Peki Scripter", 32, UIFontWeightBold, UIColor.whiteColor);
    UILabel *subtitle = SCISettingsLabel(@"Your Instagram. Your rules.", 15, UIFontWeightRegular, UIColor.secondaryLabelColor);
    UILabel *modules = SCISettingsLabel(@"PRIVACY   /   MEDIA   /   CONTROL", 10, UIFontWeightSemibold, UIColor.tertiaryLabelColor);
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[badge, title, subtitle, modules]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [stack setCustomSpacing:6 afterView:title];
    [stack setCustomSpacing:22 afterView:subtitle];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [card.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [card.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [card.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],
        [card.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-12],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:26],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-26]
    ]];
    self.tableView.tableHeaderView = header;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *header = self.tableView.tableHeaderView;
    if (!header) return;
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    CGFloat height = [header systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
        withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    if (fabs(header.frame.size.height - height) > 0.5 || header.frame.size.width != width) {
        header.frame = CGRectMake(0, 0, width, height);
        self.tableView.tableHeaderView = header;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"SCInstaFirstRun"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Peki Scripter Settings Info"
                                                                       message:@"In the future: Hold down on the three lines at the top right of your profile page, to re-open Peki Scripter settings."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"I understand!"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        
        UIViewController *presenter = self.presentingViewController;
        [presenter presentViewController:alert animated:YES completion:nil];
        
        // Done with first-time setup for this version
        [[NSUserDefaults standardUserDefaults] setValue:SCIVersionString forKey:@"SCInstaFirstRun"];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (!row) return nil;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UIListContentConfiguration *cellContentConfig = cell.defaultContentConfiguration;
    UIBackgroundConfiguration *background = [UIBackgroundConfiguration listGroupedCellConfiguration];
    background.backgroundColor = SCISettingsSurface();
    cell.backgroundConfiguration = background;
    cell.tintColor = [SCIUtils SCIColor_Primary];
    cellContentConfig.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(17, 18, 17, 18);
    cellContentConfig.textProperties.font = [[UIFontMetrics defaultMetrics]
        scaledFontForFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
    cellContentConfig.textProperties.color = UIColor.whiteColor;
    cellContentConfig.secondaryTextProperties.font = [[UIFontMetrics defaultMetrics]
        scaledFontForFont:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular]];
    cellContentConfig.secondaryTextProperties.color = UIColor.secondaryLabelColor;
    cellContentConfig.textProperties.numberOfLines = 0;
    cellContentConfig.secondaryTextProperties.numberOfLines = 0;
    cellContentConfig.imageToTextPadding = 16;
    
    cellContentConfig.text = row.title;
    
    // Subtitle
    if (row.subtitle.length) {
        cellContentConfig.secondaryText = row.subtitle;
        cellContentConfig.textToSecondaryTextVerticalPadding = 4.5;
    }
    
    // Icon
    if (row.icon != nil) {
        cellContentConfig.image = [row.icon image];
        cellContentConfig.imageProperties.tintColor = [UIColor colorWithRed:0.50 green:0.69 blue:1 alpha:1];
    }
    
    // Image url
    if (row.imageUrl != nil) {
        [self loadImageFromURL:row.imageUrl atIndexPath:indexPath forTableView:tableView];
        
        cellContentConfig.imageToTextPadding = 14;
    }
    
    switch (row.type) {
        case SCITableCellStatic: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellLink: {
            cellContentConfig.textProperties.color = [UIColor colorWithRed:0.50 green:0.69 blue:1 alpha:1];
            cellContentConfig.textProperties.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize
                                                                      weight:UIFontWeightMedium];
            
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"safari"]];
            imageView.tintColor = [UIColor systemGray3Color];
            cell.accessoryView = imageView;
            
            break;
        }
            
        case SCITableCellSwitch: {
            UISwitch *toggle = [UISwitch new];
            toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:row.defaultsKey];
            toggle.onTintColor = [SCIUtils SCIColor_Primary];
            
            objc_setAssociatedObject(toggle, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = toggle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellStepper: {
            UIStepper *stepper = [UIStepper new];
            stepper.minimumValue = row.min;
            stepper.maximumValue = row.max;
            stepper.stepValue = row.step;
            stepper.value = [[NSUserDefaults standardUserDefaults] doubleForKey:row.defaultsKey];
            
            objc_setAssociatedObject(stepper, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [stepper addTarget:self
                        action:@selector(stepperChanged:)
              forControlEvents:UIControlEventValueChanged];
            
            // Template subtitle
            if (row.subtitle.length) {
                cellContentConfig.secondaryText = [self formatString:row.subtitle withValue:stepper.value label:row.label singularLabel:row.singularLabel];
            }
            
            cell.accessoryView = stepper;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellButton: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
            
        case SCITableCellMenu: {
            UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [menuButton setTitle:@"•••" forState:UIControlStateNormal];
            menuButton.menu = [row menuForButton:menuButton];
            menuButton.showsMenuAsPrimaryAction = YES;
            menuButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize
                                                           weight:UIFontWeightMedium];
            
            UIButtonConfiguration *config = menuButton.configuration ?: [UIButtonConfiguration plainButtonConfiguration];
            config.contentInsets = NSDirectionalEdgeInsetsMake(8, 12, 8, 12);
            config.baseForegroundColor = [SCIUtils SCIColor_Primary];
            menuButton.configuration = config;

            [menuButton sizeToFit];
            
            cell.accessoryView = menuButton;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellNavigation: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }
    
    cell.contentConfiguration = cellContentConfig;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.sections[section][@"footer"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (![view isKindOfClass:[UITableViewHeaderFooterView class]]) return;
    UILabel *label = ((UITableViewHeaderFooterView *)view).textLabel;
    label.textColor = [UIColor colorWithRed:0.46 green:0.53 blue:0.65 alpha:1];
    label.font = [[UIFontMetrics defaultMetrics] scaledFontForFont:[UIFont systemFontOfSize:11 weight:UIFontWeightBold]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (!row) return;

    if (row.type == SCITableCellLink) {
        [[UIApplication sharedApplication] openURL:row.url options:@{} completionHandler:nil];
    }
    else if (row.type == SCITableCellButton) {
        if (row.action != nil) {
            row.action();
        }
    }
    else if (row.type == SCITableCellNavigation) {
        if (row.navSections.count > 0) {
            UIViewController *vc = [[SCISettingsViewController alloc] initWithTitle:row.title sections:row.navSections reduceMargin:NO];
            vc.title = row.title;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (void)switchChanged:(UISwitch *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    
    NSLog(@"Switch changed: %@", sender.isOn ? @"ON" : @"OFF");
    
    if (row.requiresRestart) {
        [SCIUtils showRestartConfirmation];
    }
}

- (void)stepperChanged:(UIStepper *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setDouble:sender.value forKey:row.defaultsKey];
    
    NSLog(@"Stepper changed: %f", sender.value);
    
    [self reloadCellForView:sender];
}

- (void)menuChanged:(UICommand *)command {
    NSDictionary *properties = command.propertyList;
    
    [[NSUserDefaults standardUserDefaults] setValue:properties[@"value"] forKey:properties[@"defaultsKey"]];
    
    NSLog(@"Menu changed: %@", command.propertyList[@"value"]);
    
    [self reloadCellForView:command.sender animated:YES];
    
    if (properties[@"requiresRestart"]) {
        [SCIUtils showRestartConfirmation];
    }
}

#pragma mark - Helper

- (NSString *)formatString:(NSString *)template withValue:(double)value label:(NSString *)label singularLabel:(NSString *)singularLabel {
    // Singular or plural labels
    NSString *applicableLabel = fabs(value - 1.0) < 0.00001 ? singularLabel : label;
    
    // Force value to 0 to prevent it being -0
    if (fabs(value) < 0.00001) {
        value = 0.0;
    }

    // Get correct decimal value based on step value
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = [SCIUtils decimalPlacesInDouble:value];

    NSString *stringValue = [formatter stringFromNumber:@(value)];

    return [NSString stringWithFormat:template, stringValue, applicableLabel];
}

- (void)reloadCellForView:(UIView *)view animated:(BOOL)animated {
    UITableViewCell *cell = (UITableViewCell *)view.superview;
    while (cell && ![cell isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *)cell.superview;
    }
    if (!cell) return;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) return;
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
}
- (void)reloadCellForView:(UIView *)view {
    [self reloadCellForView:view animated:NO];
}

- (void)loadImageFromURL:(NSURL *)url atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    if (!url) return;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (!data || error) return;

        UIImage *image = [UIImage imageWithData:data];
        if (!image) return;

        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (!cell) return;

            UIListContentConfiguration *config = (UIListContentConfiguration *)cell.contentConfiguration;
            config.image = image;
            config.imageProperties.maximumSize = CGSizeMake(45, 45);
            cell.contentConfiguration = config;
        });
    }];

    [task resume];
}

@end
