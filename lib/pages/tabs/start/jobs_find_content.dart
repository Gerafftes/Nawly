import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import '../../../data/job_map_region_repository.dart';
import '../../../data/jobs_find_repository.dart';
import '../../../models/job_models.dart';
import 'jobs_filter_sheet.dart';
import '../../../services/ui_scale.dart';
import '../../../widgets/job_card.dart';
import '../../../widgets/jobs_map.dart';

const String _jobsFilterConfirmLabel = 'Bestätigen';

class JobsFindContent extends StatefulWidget {
  final Color cardColor;
  final Color secondaryText;
  final Color borderColor;
  final Color textColor;
  final Color jobCardColor;
  final Color jobButtonColor;
  final Color timeTextColor;
  final Color filterIconColor;
  final String themeMode;
  final Color buttonTextColor;
  final AppleLiquidSheetController sheetController;
  final Future<void> Function()? onBeforeSheetPresented;
  final VoidCallback? onSheetClosed;
  final JobsFindRepository jobsRepository;
  final JobMapRegionRepository mapRegionRepository;

  const JobsFindContent({
    super.key,
    required this.cardColor,
    required this.secondaryText,
    required this.borderColor,
    required this.textColor,
    required this.jobCardColor,
    required this.jobButtonColor,
    required this.timeTextColor,
    required this.filterIconColor,
    required this.themeMode,
    required this.buttonTextColor,
    required this.sheetController,
    this.onBeforeSheetPresented,
    this.onSheetClosed,
    this.jobsRepository = const JobsFindDemoRepository(),
    this.mapRegionRepository = const JobMapRegionDemoRepository(),
  });

  @override
  State<JobsFindContent> createState() => _JobsFindContentState();
}

class _JobsFindContentState extends State<JobsFindContent> {
  late final Future<List<JobFindData>> _jobsFuture;
  late final Future<JobMapRegion> _mapRegionFuture;
  bool _isMapViewActive = false;
  bool _isFilterSheetOpen = false;
  Set<String> _selectedCategories = <String>{'Alle'};

  @override
  void initState() {
    super.initState();
    _jobsFuture = widget.jobsRepository.loadJobs();
    _mapRegionFuture = widget.mapRegionRepository.loadRegion();
  }

  String get _viewButtonTitle =>
      _isMapViewActive ? 'Listenansicht' : 'Kartenansicht';

  Future<void> _withFilterSheetLifecycle(Future<void> Function() show) async {
    if (_isFilterSheetOpen) {
      return;
    }
    _isFilterSheetOpen = true;
    try {
      await widget.onBeforeSheetPresented?.call();
      if (mounted) {
        await show();
      }
    } finally {
      _isFilterSheetOpen = false;
      widget.onSheetClosed?.call();
    }
  }

  void _toggleJobsView() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isMapViewActive = !_isMapViewActive;
    });
  }

  void _updateSelectedCategories(Iterable<String> categories) {
    if (!mounted) return;
    final Set<String> selection = categories
        .where(jobsFilterCategoryOptions.contains)
        .toSet();
    setState(() {
      _selectedCategories = selection.isEmpty ? <String>{'Alle'} : selection;
    });
  }

  AppleLiquidSheetContent _buildJobsFilterSheetContent() {
    return AppleLiquidSheetContent(
      title: 'Filter',
      doneSemanticLabel: _jobsFilterConfirmLabel,
      showsSectionBackgrounds: false,
      sectionSpacing: 2,
      leadingAction: const AppleLiquidSheetToolbarAction(
        systemImage: 'xmark',
        semanticLabel: 'Schließen',
        foregroundColor: Color(0xFFE6E6E6),
      ),
      trailingAction: const AppleLiquidSheetToolbarAction(
        systemImage: 'checkmark',
        semanticLabel: _jobsFilterConfirmLabel,
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF007AFF),
      ),
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          rows: <AppleLiquidSheetRow>[
            const AppleLiquidSheetRow.slider(
              title: 'Distanz',
              value: 5,
              min: 1,
              max: 15,
              step: 1,
              valueSuffix: 'km',
              tintColor: Color(0xFF007AFF),
              valuePlacement: AppleLiquidSheetSliderValuePlacement.besideTrack,
              rowHorizontalInset: 8,
            ),
          ],
        ),
        AppleLiquidSheetSection(
          title: 'Kategorie',
          titleColor: const Color(0xFFE6E6E6),
          titleHorizontalInset: 8,
          titleSpacing: 0,
          showsBackground: true,
          backgroundColor: const Color(0xFF0D0D0D),
          borderColor: const Color(0xFF0D0D0D),
          cornerRadius: 15,
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.multiPicker(
              title: 'Kategorie',
              options: jobsFilterCategoryOptions,
              selectedOptions: _selectedCategories.toList(growable: false),
              chevronColor: const Color(0xFFF2F2F2),
              selectionLabelPlacement:
                  AppleLiquidSheetMultiPickerLabelPlacement.primary,
              onSelectionChanged: _updateSelectedCategories,
            ),
          ],
        ),
        AppleLiquidSheetSection(
          rows: <AppleLiquidSheetRow>[
            const AppleLiquidSheetRow.segmented(
              title: 'Sortiert von',
              firstOption: 'Neu zu Alt',
              secondOption: 'Alt zu Neu',
              selectedOption: 'Neu zu Alt',
              style: AppleLiquidSheetSegmentedStyle(
                selectedBackgroundColor: Color(0xFF0D0D0D),
                unselectedBackgroundColor: Color(0xFF0D0D0D),
                selectedTextColor: Color(0xFF1EACFF),
                unselectedTextColor: Color(0xFFE6E6E6),
                titleColor: Color(0xFFE6E6E6),
                contentSpacing: 10,
                verticalPadding: 2,
                rowHorizontalInset: 8,
                borderWidth: 0,
                selectedShadowRadius: 0,
                selectedShadowOffsetY: 0,
              ),
            ),
          ],
        ),
        AppleLiquidSheetSection(
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.button(
              title: _viewButtonTitle,
              tintColor: const Color(0xFF007AFF),
              dismissesSheet: true,
              style: const AppleLiquidSheetButtonStyle(
                foregroundColor: Color(0xFFE6E6E6),
                buttonHeight: 60,
                rowHorizontalInset: 8,
                rowTopInset: 14,
                rowBottomInset: 4,
              ),
              onPressed: _toggleJobsView,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = UiScale.of(context, designWidth: 402);
    double s(double value) => ui.s(value);
    final double infoCardMinHeight = s(106);
    final double sectionHeaderHeight = s(44);
    final bool isDark = widget.themeMode == 'auto'
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : widget.themeMode == 'dark';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info-Card
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: infoCardMinHeight),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(s(15), s(15), s(15), s(15)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(s(15)),
              border: Border.all(color: widget.borderColor, width: s(2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finde Mini-Jobs in deiner Nähe',
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: s(20),
                    height: 1,
                  ),
                ),
                SizedBox(height: s(8)),
                Text(
                  'Wähle einen Job, der zu Zeit, Ort und Bezahlung passt.',
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: TextStyle(
                    color: widget.secondaryText,
                    fontSize: s(15),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: s(28)),
        SizedBox(
          height: sectionHeaderHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'In deiner Nähe',
                style: TextStyle(
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: s(20),
                ),
              ),
              IconButton(
                onPressed: () => _withFilterSheetLifecycle(() async {
                  final bool didShowNativeSheet = await widget.sheetController
                      .showSheet(
                        content: _buildJobsFilterSheetContent(),
                        scrollContext: context,
                      );
                  if (didShowNativeSheet) {
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }

                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: isDark
                        ? const Color(0xFF0D0D0D)
                        : const Color(0xFFE6E6E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(s(24)),
                      ),
                    ),
                    builder: (context) => JobsFilterSheet(
                      isDark: isDark,
                      selectedCategories: _selectedCategories,
                      onCategoriesChanged: _updateSelectedCategories,
                      viewButtonTitle: _viewButtonTitle,
                      onToggleView: _toggleJobsView,
                    ),
                  );
                }),
                icon: Icon(
                  Icons.tune,
                  color: widget.filterIconColor,
                  size: s(28),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: widget.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s(8)),
                  ),
                  padding: EdgeInsets.all(s(8)),
                  fixedSize: Size(sectionHeaderHeight, sectionHeaderHeight),
                  minimumSize: Size(sectionHeaderHeight, sectionHeaderHeight),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        if (!_isMapViewActive) ...[
          SizedBox(height: s(12)),
          FutureBuilder<List<JobFindData>>(
            future: _jobsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Jobs konnten nicht geladen werden.',
                  style: TextStyle(
                    color: widget.secondaryText,
                    fontSize: s(15),
                  ),
                );
              }

              final List<JobFindData>? jobs = snapshot.data;
              if (jobs == null) {
                return SizedBox(height: s(12));
              }

              return Column(
                children: [
                  for (int index = 0; index < jobs.length; index++) ...[
                    if (index > 0) SizedBox(height: s(12)),
                    JobCard(
                      title: jobs[index].title,
                      time: jobs[index].time,
                      price: jobs[index].price,
                      distance: jobs[index].distance,
                      color: widget.jobCardColor,
                      textColor: widget.textColor,
                      buttonColor: widget.jobButtonColor,
                      timeTextColor: widget.timeTextColor,
                      buttonTextColor: widget.buttonTextColor,
                      showVerified: jobs[index].showVerified,
                    ),
                  ],
                ],
              );
            },
          ),
        ] else ...[
          SizedBox(height: s(12)),
          FutureBuilder<List<JobFindData>>(
            future: _jobsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Karte konnte nicht geladen werden.',
                  style: TextStyle(
                    color: widget.secondaryText,
                    fontSize: s(15),
                  ),
                );
              }

              final List<JobFindData>? jobs = snapshot.data;
              if (jobs == null) {
                return SizedBox(height: s(12));
              }

              return FutureBuilder<JobMapRegion>(
                future: _mapRegionFuture,
                builder: (context, regionSnapshot) {
                  if (regionSnapshot.hasError) {
                    return Text(
                      'Kartenregion konnte nicht geladen werden.',
                      style: TextStyle(
                        color: widget.secondaryText,
                        fontSize: s(15),
                      ),
                    );
                  }

                  final JobMapRegion? region = regionSnapshot.data;
                  if (region == null) {
                    return SizedBox(height: s(12));
                  }

                  return JobsMap(
                    jobs: jobs,
                    region: region,
                    borderColor: widget.borderColor,
                    textColor: widget.textColor,
                    secondaryTextColor: widget.timeTextColor,
                    cardColor: widget.jobCardColor,
                    buttonColor: widget.jobButtonColor,
                    buttonTextColor: widget.buttonTextColor,
                    isDark: isDark,
                    onBeforeFullscreenPresented: widget.onBeforeSheetPresented,
                    onFullscreenClosed: widget.onSheetClosed,
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}
