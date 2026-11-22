#import "SCISettingsViewController.h"
#import "../Appearance/SCITheme.h"
#import "../Appearance/SCIBrandMarkView.h"

static char rowStaticRef[] = "row";

static UIColor *SCISettingsBackground(void) {
    return SCITheme.backgroundColor;
}

static UIColor *SCISettingsSurface(void) {
    return SCITheme.surfaceColor;
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

static UIImage *SCICategoryIcon(SCISymbol *symbol) {
    UIImage *image = [symbol image];
    if (!image || image.size.width <= 0 || image.size.height <= 0) return image;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(32, 32)];
    return [[renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        UIColor *accent = SCITheme.accentColor;
        [[accent colorWithAlphaComponent:0.08] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 32, 32) cornerRadius:9] fill];
        CGFloat scale = MIN(17 / image.size.width, 17 / image.size.height);
        CGSize size = CGSizeMake(image.size.width * scale, image.size.height * scale);
        [[image imageWithTintColor:accent renderingMode:UIImageRenderingModeAlwaysOriginal]
            drawInRect:CGRectMake((32 - size.width) / 2, (32 - size.height) / 2, size.width, size.height)];
    }] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;
@property (nonatomic, copy) NSArray *allSections;
@property (nonatomic, strong) UIView *dashboardHeader;

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
        
        if (reduceMargin && mutableSections.count) {
            // Each category gets its own card rather than one long stock list.
            NSDictionary *modules = mutableSections.firstObject;
            NSMutableArray *cards = [NSMutableArray new];
            NSArray *rows = modules[@"rows"];
            for (NSUInteger index = 0; index < rows.count; index++) {
                [cards addObject:@{
                    @"header": index == 0 ? (modules[@"header"] ?: @"") : @"",
                    @"footer": index == rows.count - 1 ? (modules[@"footer"] ?: @"") : @"",
                    @"rows": @[rows[index]]
                }];
            }
            [mutableSections removeObjectAtIndex:0];
            [cards addObjectsFromArray:mutableSections];
            mutableSections = cards;
        }
        self.sections = [mutableSections copy];
        self.allSections = self.sections;
    }
    
    
    return self;
}

- (instancetype)init {
    return [self initWithTitle:[SCITweakSettings title] sections:[SCITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.overrideUserInterfaceStyle = SCITheme.interfaceStyle;
    self.navigationController.overrideUserInterfaceStyle = SCITheme.interfaceStyle;
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    [self applyAppearance];
    if (self.reduceMargin) {
        self.navigationItem.title = [SCITweakSettings title];
        self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings:)];
        UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:nil];
        search.searchResultsUpdater = self;
        search.obscuresBackgroundDuringPresentation = NO;
        search.searchBar.placeholder = @"Search";
        self.navigationItem.searchController = search;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        self.definesPresentationContext = YES;
    }

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    self.tableView.delegate = self;
    self.tableView.backgroundColor = SCISettingsBackground();
    self.tableView.tintColor = SCITheme.accentColor;
    self.tableView.separatorColor = SCITheme.borderColor;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 76;
    self.tableView.sectionHeaderTopPadding = 8;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(settingsUpdated:)
        name:SCISettingsDidChangeNotification object:nil];
    if (self.reduceMargin) [self buildDashboardHeader];
}

- (void)applyAppearance {
    self.overrideUserInterfaceStyle = SCITheme.interfaceStyle;
    self.navigationController.overrideUserInterfaceStyle = SCITheme.interfaceStyle;
    UINavigationBarAppearance *navigationAppearance = [UINavigationBarAppearance new];
    [navigationAppearance configureWithOpaqueBackground];
    navigationAppearance.backgroundColor = SCISettingsBackground();
    navigationAppearance.shadowColor = UIColor.clearColor;
    navigationAppearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: SCITheme.textColor,
        NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]
    };
    self.navigationController.navigationBar.standardAppearance = navigationAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = navigationAppearance;
    self.navigationController.navigationBar.compactAppearance = navigationAppearance;
    self.navigationController.navigationBar.tintColor = SCITheme.accentColor;
    self.view.backgroundColor = SCISettingsBackground();
    self.tableView.backgroundColor = SCISettingsBackground();
    self.tableView.tintColor = SCITheme.accentColor;
    self.tableView.separatorColor = SCITheme.borderColor;
    self.navigationItem.searchController.searchBar.tintColor = SCITheme.accentColor;
}

- (void)settingsUpdated:(NSNotification *)notification {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self settingsUpdated:notification]; });
        return;
    }
    [self applyAppearance];
    [self.tableView reloadData];
    if (self.reduceMargin && !self.navigationItem.searchController.searchBar.text.length) [self buildDashboardHeader];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyAppearance];
    [self.tableView reloadData];
    if (self.reduceMargin && !self.navigationItem.searchController.searchBar.text.length) [self buildDashboardHeader];
}

- (void)closeSettings:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)buildDashboardHeader {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 76)];
    SCIBrandMarkView *mark = [SCIBrandMarkView new];
    mark.translatesAutoresizingMaskIntoConstraints = NO;
    mark.tintColor = SCITheme.accentColor;
    [mark.widthAnchor constraintEqualToConstant:44].active = YES;
    [mark.heightAnchor constraintEqualToConstant:44].active = YES;
    UIButton *handle = [UIButton buttonWithType:UIButtonTypeSystem];
    [handle setTitle:@"@pekifn" forState:UIControlStateNormal];
    [handle setTitleColor:SCITheme.textColor forState:UIControlStateNormal];
    handle.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    handle.titleLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline]
        scaledFontForFont:[UIFont systemFontOfSize:17 weight:UIFontWeightMedium]];
    handle.titleLabel.adjustsFontForContentSizeCategory = YES;
    handle.titleLabel.numberOfLines = 0;
    [handle.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    [handle addTarget:self action:@selector(openInstagramProfile:) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *identity = [[UIStackView alloc] initWithArrangedSubviews:@[mark, handle]];
    identity.spacing = 12;
    identity.alignment = UIStackViewAlignmentCenter;
    identity.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:identity];
    [NSLayoutConstraint activateConstraints:@[
        [identity.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:24],
        [identity.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-24],
        [identity.topAnchor constraintEqualToAnchor:header.topAnchor constant:12],
        [identity.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-20]
    ]];
    self.dashboardHeader = header;
    self.tableView.tableHeaderView = header;
}

- (void)openInstagramProfile:(id)sender {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.instagram.com/pekifn/"]
        options:@{} completionHandler:nil];
}

- (void)collectMatches:(NSArray *)sections query:(NSString *)query path:(NSString *)path into:(NSMutableArray *)results {
    for (NSDictionary *section in sections) {
        NSMutableArray *matches = [NSMutableArray new];
        for (SCISetting *row in section[@"rows"]) {
            if (row.type == SCITableCellNavigation) {
                if ([row.title localizedCaseInsensitiveContainsString:query]) {
                    [matches addObject:row];
                } else {
                    [self collectMatches:row.navSections query:query path:row.title into:results];
                }
            } else if ([row.title localizedCaseInsensitiveContainsString:query]
                || [row.subtitle localizedCaseInsensitiveContainsString:query]) {
                [matches addObject:row];
            }
        }
        if (matches.count) {
            [results addObject:@{@"header": path.length ? path : (section[@"header"] ?: @""), @"rows": matches}];
        }
    }
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query = [searchController.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (query.length) {
        NSMutableArray *matches = [NSMutableArray new];
        [self collectMatches:self.allSections query:query path:@"" into:matches];
        self.sections = matches;
        self.tableView.tableHeaderView = nil;
    } else {
        self.sections = self.allSections;
        [self buildDashboardHeader];
    }
    if (query.length && !self.sections.count) {
        UILabel *empty = SCISettingsLabel(@"No matching settings", 15, UIFontWeightMedium, SCITheme.secondaryTextColor);
        empty.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = empty;
    } else {
        self.tableView.backgroundView = nil;
    }
    [self.tableView reloadData];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.reduceMargin) [NSUserDefaults.standardUserDefaults setObject:SCIVersionString forKey:@"SCInstaFirstRun"];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (!row) return nil;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UIListContentConfiguration *cellContentConfig = cell.defaultContentConfiguration;
    UIBackgroundConfiguration *background = [UIBackgroundConfiguration listGroupedCellConfiguration];
    background.backgroundColor = SCISettingsSurface();
    if (self.reduceMargin) {
        background.cornerRadius = 12;
        background.strokeWidth = 0.5;
        background.strokeColor = SCITheme.borderColor;
    }
    cell.backgroundConfiguration = background;
    cell.tintColor = SCITheme.accentColor;
    cellContentConfig.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(14, 16, 14, 16);
    cellContentConfig.textProperties.font = [[UIFontMetrics defaultMetrics]
        scaledFontForFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];
    cellContentConfig.textProperties.color = SCITheme.cellTextColor;
    cellContentConfig.secondaryTextProperties.font = [[UIFontMetrics defaultMetrics]
        scaledFontForFont:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular]];
    cellContentConfig.secondaryTextProperties.color = SCITheme.cellSecondaryTextColor;
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
        cellContentConfig.image = self.reduceMargin ? SCICategoryIcon(row.icon) : [row.icon image];
        cellContentConfig.imageProperties.tintColor = SCITheme.accentColor;
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
            cellContentConfig.textProperties.color = SCITheme.accentColor;
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
            toggle.onTintColor = SCITheme.accentColor;
            
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
            config.baseForegroundColor = SCITheme.accentColor;
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
        case SCITableCellController: {
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
    label.textColor = SCITheme.secondaryTextColor;
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
    else if (row.type == SCITableCellController && row.controllerFactory) {
        UIViewController *controller = row.controllerFactory();
        if (controller) {
            self.navigationItem.searchController.active = NO;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (void)switchChanged:(UISwitch *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:SCISettingsDidChangeNotification object:nil];
    
    NSLog(@"Switch changed: %@", sender.isOn ? @"ON" : @"OFF");
    
    if (row.requiresRestart) {
        [SCIUtils showRestartConfirmation];
    }
}

- (void)stepperChanged:(UIStepper *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setDouble:sender.value forKey:row.defaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:SCISettingsDidChangeNotification object:nil];
    
    NSLog(@"Stepper changed: %f", sender.value);
    
    [self reloadCellForView:sender];
}

- (void)menuChanged:(UICommand *)command {
    NSDictionary *properties = command.propertyList;
    
    [[NSUserDefaults standardUserDefaults] setValue:properties[@"value"] forKey:properties[@"defaultsKey"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SCISettingsDidChangeNotification object:nil];
    if ([properties[@"defaultsKey"] hasPrefix:@"settings_"]) [self applyAppearance];
    
    NSLog(@"Menu changed: %@", command.propertyList[@"value"]);
    
    [self.tableView reloadData];
    
    if ([properties[@"requiresRestart"] boolValue]) {
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
