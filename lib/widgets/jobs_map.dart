import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/job_models.dart';
import '../services/ui_scale.dart';
import 'job_card.dart';

const String _openStreetMapTileUrl = String.fromEnvironment(
  'NAWLY_MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);
final Uri _openStreetMapCopyrightUri = Uri.parse(
  'https://www.openstreetmap.org/copyright',
);
const double _initialMapRadiusMeters = 5000;
const Distance _distance = Distance();

class JobsMap extends StatefulWidget {
  const JobsMap({
    super.key,
    required this.jobs,
    required this.region,
    required this.borderColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.cardColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.isDark,
    this.tileProvider,
    this.isFullscreen = false,
    this.onBeforeFullscreenPresented,
    this.onFullscreenClosed,
  });

  final List<JobFindData> jobs;
  final JobMapRegion region;
  final Color borderColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color cardColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final bool isDark;
  final TileProvider? tileProvider;
  final bool isFullscreen;
  final Future<void> Function()? onBeforeFullscreenPresented;
  final VoidCallback? onFullscreenClosed;

  @override
  State<JobsMap> createState() => _JobsMapState();
}

class _JobsMapState extends State<JobsMap> {
  JobFindData? _selectedJob;
  bool _isOpeningFullscreen = false;
  late List<Polygon<String>> _regionPolygons;

  List<JobFindData> get _mappableJobs => widget.jobs
      .where((JobFindData job) => job.approximateLocation != null)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _cacheRegionGeometry();
  }

  @override
  void didUpdateWidget(covariant JobsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region) {
      _cacheRegionGeometry();
    }
  }

  void _cacheRegionGeometry() {
    _regionPolygons = widget.region.polygons
        .map((JobMapRegionPolygon polygon) {
          return Polygon<String>(
            points: polygon.outer.map(_toLatLng).toList(growable: false),
            holePointsList: polygon.holes
                .map(
                  (List<JobMapCoordinate> hole) =>
                      hole.map(_toLatLng).toList(growable: false),
                )
                .toList(growable: false),
            borderColor: const Color(0xFFFF453A),
            borderStrokeWidth: 3,
            hitValue: widget.region.id,
          );
        })
        .toList(growable: false);
  }

  LatLng _toLatLng(JobMapCoordinate coordinate) =>
      LatLng(coordinate.latitude, coordinate.longitude);

  LatLng _initialCenter(List<JobFindData> jobs) {
    final double latitude = jobs.fold<double>(
      0,
      (double sum, JobFindData job) => sum + job.approximateLocation!.latitude,
    );
    final double longitude = jobs.fold<double>(
      0,
      (double sum, JobFindData job) => sum + job.approximateLocation!.longitude,
    );
    return LatLng(latitude / jobs.length, longitude / jobs.length);
  }

  LatLngBounds _initialViewportBounds(List<JobFindData> jobs) {
    final LatLng center = _initialCenter(jobs);
    // ponytail: Use the demo jobs' center until a real device-location flow is
    // available. Only this center needs replacing when that flow is added.
    return LatLngBounds.fromPoints(<LatLng>[
      _distance.offset(center, _initialMapRadiusMeters, 0),
      _distance.offset(center, _initialMapRadiusMeters, 90),
      _distance.offset(center, _initialMapRadiusMeters, 180),
      _distance.offset(center, _initialMapRadiusMeters, 270),
    ]);
  }

  void _selectJob(JobFindData job) {
    setState(() {
      _selectedJob = job;
    });
  }

  @override
  Widget build(BuildContext context) {
    final UiScale ui = UiScale.of(context, designWidth: 402);
    final List<JobFindData> jobs = _mappableJobs;
    final Color mapOverlayBackground = widget.isDark
        ? const Color(0xE61A1A1A)
        : const Color(0xE6FFFFFF);
    final Color mapOverlayForeground = widget.isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF0D0D0D);
    final double fullscreenBottomInset = widget.isFullscreen
        ? MediaQuery.paddingOf(context).bottom
        : 0;

    if (jobs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(ui.s(18)),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(ui.s(15)),
        ),
        child: Text(
          'Für diese Jobs sind noch keine öffentlichen Standorte verfügbar.',
          style: TextStyle(
            color: widget.secondaryTextColor,
            fontSize: ui.s(15),
            height: 1.4,
          ),
        ),
      );
    }

    final BorderRadius mapBorderRadius = BorderRadius.circular(
      widget.isFullscreen ? 0 : ui.s(15),
    );
    final Widget map = Container(
      key: ValueKey<String>(
        widget.isFullscreen ? 'fullscreen-jobs-map' : 'jobs-map',
      ),
      height: widget.isFullscreen ? null : ui.s(330).clamp(280, 360),
      padding: EdgeInsets.all(widget.isFullscreen ? 0 : ui.s(1.5)),
      decoration: BoxDecoration(
        color: widget.borderColor,
        borderRadius: mapBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: mapBorderRadius,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: _initialViewportBounds(jobs),
            ),
            minZoom: 4,
            maxZoom: 18,
          ),
          children: <Widget>[
            _buildTileLayer(context),
            PolygonLayer<String>(
              key: ValueKey<String>('job-region-${widget.region.id}'),
              polygons: _regionPolygons,
              polygonCulling: false,
              invertedFill: widget.isDark
                  ? const Color(0x99000000)
                  : const Color(0x730F172A),
            ),
            MarkerLayer(
              // ponytail: Load the small public result set at once; use a
              // PostGIS viewport query when production job volume grows.
              markers: <Marker>[
                for (final JobFindData job in jobs)
                  Marker(
                    key: ValueKey<String>('job-marker-${job.id}'),
                    point: LatLng(
                      job.approximateLocation!.latitude,
                      job.approximateLocation!.longitude,
                    ),
                    width: ui.s(52),
                    height: ui.s(52),
                    child: Semantics(
                      button: true,
                      label: '${job.title}, ${job.distance}, ${job.price}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _selectJob(job),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedJob?.id == job.id
                                    ? Colors.white
                                    : const Color(0xCCFFFFFF),
                                width: _selectedJob?.id == job.id
                                    ? ui.s(4)
                                    : ui.s(2),
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.work_rounded,
                              color: Colors.white,
                              size: ui.s(23),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              top: ui.s(10),
              left: ui.s(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: mapOverlayBackground,
                  borderRadius: BorderRadius.circular(ui.s(9)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ui.s(10),
                    vertical: ui.s(7),
                  ),
                  child: Text(
                    '${widget.region.name} · Ungefähre Standorte',
                    style: TextStyle(
                      color: mapOverlayForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: widget.isFullscreen
                  ? Alignment.bottomLeft
                  : Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.isFullscreen ? ui.s(8) : 0,
                  bottom: fullscreenBottomInset,
                ),
                child: Semantics(
                  link: true,
                  label: 'Kartendaten: OpenStreetMap contributors',
                  child: GestureDetector(
                    onTap: () async {
                      await launchUrl(_openStreetMapCopyrightUri);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ColoredBox(
                        color: mapOverlayBackground,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ui.s(5),
                            vertical: ui.s(3),
                          ),
                          child: Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(
                              color: mapOverlayForeground,
                              fontSize: ui.s(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: ui.s(10),
              right: ui.s(10),
              child: IconButton(
                key: ValueKey<String>(
                  widget.isFullscreen
                      ? 'close-fullscreen-map'
                      : 'open-fullscreen-map',
                ),
                tooltip: widget.isFullscreen
                    ? 'Vollbild schließen'
                    : 'Karte im Vollbild öffnen',
                onPressed: widget.isFullscreen
                    ? () => Navigator.of(context).pop()
                    : () => _openFullscreenMap(jobs),
                icon: Icon(
                  widget.isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  color: mapOverlayForeground,
                  size: ui.s(24),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: mapOverlayBackground,
                  fixedSize: Size(ui.s(44), ui.s(44)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ui.s(9)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isFullscreen) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          map,
          if (_selectedJob != null)
            Positioned(
              left: ui.s(16),
              right: ui.s(16),
              bottom: ui.s(28) + fullscreenBottomInset,
              child: _buildSelectedJobDetails(ui),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        map,
        SizedBox(height: ui.s(12)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _selectedJob == null
              ? Padding(
                  key: const ValueKey<String>('map-selection-hint'),
                  padding: EdgeInsets.symmetric(horizontal: ui.s(2)),
                  child: Text(
                    'Tippe auf einen Marker, um den Job anzusehen.',
                    style: TextStyle(
                      color: widget.secondaryTextColor,
                      fontSize: ui.s(14),
                    ),
                  ),
                )
              : _buildSelectedJobDetails(ui),
        ),
      ],
    );
  }

  Future<void> _openFullscreenMap(List<JobFindData> jobs) async {
    if (_isOpeningFullscreen) {
      return;
    }
    _isOpeningFullscreen = true;

    try {
      await widget.onBeforeFullscreenPresented?.call();
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => Scaffold(
            backgroundColor: widget.isDark
                ? const Color(0xFF0D0D0D)
                : const Color(0xFFF2F2F2),
            body: SafeArea(
              bottom: false,
              child: JobsMap(
                jobs: jobs,
                region: widget.region,
                borderColor: widget.borderColor,
                textColor: widget.textColor,
                secondaryTextColor: widget.secondaryTextColor,
                cardColor: widget.cardColor,
                buttonColor: widget.buttonColor,
                buttonTextColor: widget.buttonTextColor,
                isDark: widget.isDark,
                tileProvider: widget.tileProvider,
                isFullscreen: true,
              ),
            ),
          ),
        ),
      );
    } finally {
      _isOpeningFullscreen = false;
      widget.onFullscreenClosed?.call();
    }
  }

  Widget _buildSelectedJobDetails(UiScale ui) {
    final JobFindData selectedJob = _selectedJob!;
    return Column(
      key: ValueKey<String>(selectedJob.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        JobCard(
          title: selectedJob.title,
          time: selectedJob.time,
          price: selectedJob.price,
          distance: selectedJob.distance,
          color: widget.cardColor,
          textColor: widget.textColor,
          buttonColor: widget.buttonColor,
          timeTextColor: widget.secondaryTextColor,
          buttonTextColor: widget.buttonTextColor,
          showVerified: selectedJob.showVerified,
        ),
        SizedBox(height: ui.s(8)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(ui.s(9)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ui.s(10),
              vertical: ui.s(7),
            ),
            child: Text(
              'Der Marker zeigt nur die ungefähre Umgebung. '
              'Eine private Adresse wird hier nicht veröffentlicht.',
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: ui.s(12.5),
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTileLayer(BuildContext context) {
    final TileLayer tileLayer = TileLayer(
      urlTemplate: _openStreetMapTileUrl,
      userAgentPackageName: 'com.nawly.nawly',
      tileProvider: widget.tileProvider,
    );
    return widget.isDark
        ? darkModeTilesContainerBuilder(context, tileLayer)
        : tileLayer;
  }
}
