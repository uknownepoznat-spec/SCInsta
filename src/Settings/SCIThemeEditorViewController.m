#import "SCIThemeEditorViewController.h"
#import "../Appearance/SCITheme.h"
#import "../Utils.h"

@interface SCIThemeEditorViewController ()
@property (nonatomic, strong) UISegmentedControl *mode;
@property (nonatomic, weak) UIAlertAction *hexSaveAction;
@end

@implementation SCIThemeEditorViewController
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Themes";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    self.mode = [[UISegmentedControl alloc] initWithItems:@[@"Presets", @"Custom"]];
    self.mode.selectedSegmentIndex = [[SCIUtils getStringPref:@"settings_theme"] isEqualToString:@"custom"] ? 1 : 0;
    [self.mode addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    [self refresh:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh:YES];
}

- (void)applyAppearance {
    self.overrideUserInterfaceStyle = SCITheme.interfaceStyle;
    self.navigationController.overrideUserInterfaceStyle = SCITheme.interfaceStyle;
    self.view.backgroundColor = SCITheme.backgroundColor;
    self.tableView.backgroundColor = SCITheme.backgroundColor;
    self.tableView.tintColor = SCITheme.accentColor;
    UINavigationBarAppearance *bar = [UINavigationBarAppearance new];
    [bar configureWithOpaqueBackground];
    bar.backgroundColor = SCITheme.backgroundColor;
    bar.shadowColor = UIColor.clearColor;
    bar.titleTextAttributes = @{NSForegroundColorAttributeName: SCITheme.textColor};
    self.navigationController.navigationBar.standardAppearance = bar;
    self.navigationController.navigationBar.scrollEdgeAppearance = bar;
    self.navigationController.navigationBar.compactAppearance = bar;
    self.navigationController.navigationBar.tintColor = SCITheme.accentColor;
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        UIBackgroundConfiguration *background = [UIBackgroundConfiguration listGroupedCellConfiguration];
        background.backgroundColor = SCITheme.surfaceColor;
        cell.backgroundConfiguration = background;
        UIListContentConfiguration *content = (UIListContentConfiguration *)cell.contentConfiguration;
        if ([content isKindOfClass:UIListContentConfiguration.class]) {
            content.textProperties.color = SCITheme.cellTextColor;
            content.secondaryTextProperties.color = SCITheme.cellSecondaryTextColor;
            cell.contentConfiguration = content;
        }
    }
}

- (void)buildPreview {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 184)];
    self.mode.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:self.mode];
    UIView *preview = [UIView new];
    preview.translatesAutoresizingMaskIntoConstraints = NO;
    preview.backgroundColor = SCITheme.surfaceColor;
    preview.layer.cornerRadius = 14;
    preview.layer.borderWidth = 0.5;
    preview.layer.borderColor = SCITheme.borderColor.CGColor;
    [header addSubview:preview];
    UILabel *title = [UILabel new];
    title.text = SCITheme.name;
    title.textColor = SCITheme.cellTextColor;
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    title.adjustsFontForContentSizeCategory = YES;
    UILabel *detail = [UILabel new];
    detail.text = @"Background · surface · accent";
    detail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    detail.adjustsFontForContentSizeCategory = YES;
    detail.textColor = SCITheme.cellSecondaryTextColor;
    detail.numberOfLines = 0;
    UIStackView *labels = [[UIStackView alloc] initWithArrangedSubviews:@[title, detail]];
    labels.axis = UILayoutConstraintAxisVertical;
    labels.spacing = 6;
    labels.translatesAutoresizingMaskIntoConstraints = NO;
    [preview addSubview:labels];
    UIView *accent = [UIView new];
    accent.translatesAutoresizingMaskIntoConstraints = NO;
    accent.backgroundColor = SCITheme.accentColor;
    accent.layer.cornerRadius = 5;
    [preview addSubview:accent];
    [NSLayoutConstraint activateConstraints:@[
        [self.mode.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [self.mode.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [self.mode.topAnchor constraintEqualToAnchor:header.topAnchor constant:12],
        [preview.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [preview.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [preview.topAnchor constraintEqualToAnchor:self.mode.bottomAnchor constant:16],
        [preview.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-12],
        [labels.leadingAnchor constraintEqualToAnchor:preview.leadingAnchor constant:18],
        [labels.trailingAnchor constraintEqualToAnchor:accent.leadingAnchor constant:-16],
        [labels.topAnchor constraintEqualToAnchor:preview.topAnchor constant:18],
        [labels.bottomAnchor constraintEqualToAnchor:preview.bottomAnchor constant:-18],
        [accent.trailingAnchor constraintEqualToAnchor:preview.trailingAnchor constant:-18],
        [accent.centerYAnchor constraintEqualToAnchor:preview.centerYAnchor],
        [accent.widthAnchor constraintEqualToConstant:10],
        [accent.heightAnchor constraintEqualToConstant:38]
    ]];
    self.tableView.tableHeaderView = header;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *header = self.tableView.tableHeaderView;
    if (!header) return;
    CGFloat width = self.tableView.bounds.size.width;
    CGFloat height = [header systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
        withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    if (fabs(header.frame.size.height - height) > 0.5 || header.frame.size.width != width) {
        header.frame = CGRectMake(0, 0, width, height);
        self.tableView.tableHeaderView = header;
    }
}

- (void)refresh:(BOOL)reload {
    [self applyAppearance];
    [self buildPreview];
    if (reload) [self.tableView reloadData];
}

- (void)publish:(BOOL)reload {
    [NSNotificationCenter.defaultCenter postNotificationName:SCISettingsDidChangeNotification object:nil];
    [self refresh:reload];
}

- (void)modeChanged:(id)sender { [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.mode.selectedSegmentIndex == 0 ? 1 : 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mode.selectedSegmentIndex == 0 ? SCITheme.presets.count : (section == 0 ? 3 : 2);
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.mode.selectedSegmentIndex == 0 ? @"16 solid-color palettes" : (section == 0 ? @"Custom colors" : @"Apply");
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.mode.selectedSegmentIndex == 0) return @"Selecting a preset applies its surface and accent immediately. No gradients or downloaded theme files.";
    return section == 0 ? @"Tap a swatch for the color picker, or tap its row to enter #RRGGBB. Text switches between light and dark to match each surface."
        : @"These colors style Peki Scripter. To also tint supported Instagram controls, enable Use theme accent in Instagram in Appearance.";
}

- (NSArray<NSArray<NSString *> *> *)customFields {
    return @[
        @[@"Background", @"settings_custom_background"],
        @[@"Surface", @"settings_custom_surface"],
        @[@"Accent", @"settings_custom_accent"]
    ];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    UIBackgroundConfiguration *background = [UIBackgroundConfiguration listGroupedCellConfiguration];
    background.backgroundColor = SCITheme.surfaceColor;
    cell.backgroundConfiguration = background;
    UIListContentConfiguration *content = cell.defaultContentConfiguration;
    content.textProperties.color = SCITheme.cellTextColor;
    content.secondaryTextProperties.color = SCITheme.cellSecondaryTextColor;
    if (self.mode.selectedSegmentIndex == 0) {
        NSDictionary *preset = SCITheme.presets[indexPath.row];
        content.text = preset[@"name"];
        content.secondaryText = [NSString stringWithFormat:@"#%@ · #%@", preset[@"background"], preset[@"accent"]];
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(32, 32)];
        content.image = [[renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [[SCITheme colorFromHex:preset[@"surface"] fallback:UIColor.grayColor] setFill];
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 32, 32) cornerRadius:9] fill];
            [[SCITheme colorFromHex:preset[@"accent"] fallback:UIColor.grayColor] setFill];
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(11, 9, 10, 14) cornerRadius:3] fill];
        }] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        if ([[SCIUtils getStringPref:@"settings_theme"] isEqualToString:preset[@"id"]]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (indexPath.section == 0) {
        NSArray *field = [self customFields][indexPath.row];
        NSString *hex = [SCIUtils getStringPref:field[1]];
        content.text = field[0];
        content.secondaryText = [@"#" stringByAppendingString:hex];
        UIColorWell *well = [UIColorWell new];
        well.supportsAlpha = NO;
        well.title = field[0];
        well.accessibilityLabel = field[0];
        well.accessibilityIdentifier = field[1];
        well.selectedColor = [SCITheme colorFromHex:hex fallback:UIColor.grayColor];
        [well addTarget:self action:@selector(colorChanged:) forControlEvents:UIControlEventValueChanged];
        [well sizeToFit];
        cell.accessoryView = well;
    } else {
        content.text = indexPath.row == 0 ? @"Use custom theme" : @"Reset custom colors";
        content.secondaryText = indexPath.row == 0 ? @"Apply the three colors above" : @"Restore Carbon's palette";
        if (indexPath.row == 1) content.textProperties.color = UIColor.systemRedColor;
    }
    cell.contentConfiguration = content;
    return cell;
}

- (void)saveColor:(NSString *)hex key:(NSString *)key reload:(BOOL)reload {
    NSString *normalized = [SCITheme normalizedHex:hex];
    if (!normalized || !key) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:normalized forKey:key];
    [defaults setObject:@"custom" forKey:@"settings_theme"];
    [defaults setObject:@"theme" forKey:@"settings_accent"];
    [self publish:reload];
}

- (void)colorChanged:(UIColorWell *)well {
    NSString *hex = [SCITheme hexFromColor:well.selectedColor];
    [self saveColor:hex key:well.accessibilityIdentifier reload:NO];
    UIView *view = well.superview;
    while (view && ![view isKindOfClass:UITableViewCell.class]) view = view.superview;
    UITableViewCell *cell = (UITableViewCell *)view;
    UIListContentConfiguration *content = (UIListContentConfiguration *)cell.contentConfiguration;
    content.secondaryText = [@"#" stringByAppendingString:hex];
    cell.contentConfiguration = content;
}

- (void)hexChanged:(UITextField *)field {
    self.hexSaveAction.enabled = [SCITheme normalizedHex:field.text] != nil;
}

- (void)editHex:(NSArray *)field {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:field[0] message:@"Enter a six-digit RGB color."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *input) {
        input.text = [@"#" stringByAppendingString:[SCIUtils getStringPref:field[1]]];
        input.placeholder = @"#RRGGBB";
        input.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        input.autocorrectionType = UITextAutocorrectionTypeNo;
        input.keyboardType = UIKeyboardTypeASCIICapable;
        [input addTarget:self action:@selector(hexChanged:) forControlEvents:UIControlEventEditingChanged];
    }];
    __weak UIAlertController *weakAlert = alert;
    UIAlertAction *save = [UIAlertAction actionWithTitle:@"Apply" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveColor:weakAlert.textFields.firstObject.text key:field[1] reload:YES];
    }];
    save.enabled = [SCITheme normalizedHex:alert.textFields.firstObject.text] != nil;
    self.hexSaveAction = save;
    [alert addAction:save];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode.selectedSegmentIndex == 0) {
        [NSUserDefaults.standardUserDefaults setObject:SCITheme.presets[indexPath.row][@"id"] forKey:@"settings_theme"];
        [NSUserDefaults.standardUserDefaults setObject:@"theme" forKey:@"settings_accent"];
        [self publish:YES];
    } else if (indexPath.section == 0) {
        [self editHex:[self customFields][indexPath.row]];
    } else if (indexPath.row == 0) {
        [NSUserDefaults.standardUserDefaults setObject:@"custom" forKey:@"settings_theme"];
        [NSUserDefaults.standardUserDefaults setObject:@"theme" forKey:@"settings_accent"];
        [self publish:YES];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset custom colors?"
            message:@"Your three custom RGB colors will be replaced with Carbon's palette."
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            NSDictionary *preset = SCITheme.presets.firstObject;
            for (NSString *component in @[@"background", @"surface", @"accent"]) {
                [NSUserDefaults.standardUserDefaults setObject:preset[component] forKey:[@"settings_custom_" stringByAppendingString:component]];
            }
            [self publish:YES];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
