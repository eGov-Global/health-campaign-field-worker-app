import 'dart:convert';

import 'package:digit_ui_components/digit_components.dart';
import 'package:digit_ui_components/theme/TextTheme/digit_text_theme.dart';
import 'package:digit_ui_components/theme/digit_extended_theme.dart';
import 'package:digit_ui_components/widgets/atoms/table_cell.dart';
import 'package:flutter/material.dart';

import '../../action_handler/action_config.dart';
import '../../blocs/flow_crud_bloc.dart';
import '../../utils/conditional_evaluator.dart';
import '../../utils/utils.dart';
import '../resolved_flow_widget.dart';

class TableWidget extends ResolvedFlowWidget {
  @override
  String get format => 'table';

  @override
  Widget buildResolved(
    Map<String, dynamic> json,
    BuildContext context,
    void Function(ActionConfig) onAction,
    ResolvedWidgetContext resolved,
  ) {
    final stateData = resolved.stateData;
    final localization = resolved.localization;

    // Use compositeKey for registry operations (includes instanceId for proper isolation)
    final compositeKey = resolved.compositeKey ?? resolved.screenKey;

    // Get navigation params for visibility evaluation
    final navigationParams = compositeKey != null
        ? FlowCrudStateRegistry().getNavigationParams(compositeKey) ?? {}
        : <String, dynamic>{};

    // Build evaluation context with navigation params
    final evalContext = {
      ...resolved.evalContext,
      'navigation': navigationParams,
      // Legacy support for existing templates
      'currentItem': resolved.state.itemData,
    };

    // Check visibility condition
    final visible = ConditionalEvaluator.evaluate(
      json['visible'] ?? true,
      evalContext,
      screenKey: resolved.screenKey,
    );

    if (visible == false) {
      return const SizedBox.shrink();
    }

    final data = Map<String, dynamic>.from(json['data'] ?? {});

    // Store raw column configuration for later evaluation
    final rawColumns = (data['columns'] as List<dynamic>?) ?? [];

    // Create column headers with resolved templates
    final columns =
        rawColumns.where((col) => col['isActive'] != false).map((col) {
      final cellValue = col['cellValue'];
      final headerTemplate = col['header']?.toString() ?? '';

      // Resolve header template using evalContext (supports {{formData.x}}, {{itemData.x}}, etc.)
      final resolvedHeader = resolveTemplate(headerTemplate, evalContext,
          screenKey: resolved.screenKey);

      return DigitTableColumn(
        header: localization?.translate(resolvedHeader) ?? resolvedHeader,
        cellValue: cellValue is String ? cellValue : jsonEncode(cellValue),
      );
    }).toList();

    // Step 1: Resolve data source from either 'rows' or 'source' (both should point to same data)
    List<dynamic> sourceList = [];

    // Prefer 'rows' if specified, fallback to 'source'
    final dataSourceKey = data['rows'] ?? data['source'];

    if (dataSourceKey != null) {
      final rowsKey = dataSourceKey.toString();

      // Strip {{ }} if present
      String cleanKey = rowsKey;
      if (rowsKey.startsWith('{{') && rowsKey.endsWith('}}')) {
        cleanKey = rowsKey.substring(2, rowsKey.length - 2).trim();
      }

      // Case 1: Singleton path
      if (cleanKey.startsWith("singleton")) {
        final resolvedSource = resolveValueRaw("{{ $cleanKey }}", null,
            screenKey: resolved.screenKey);
        if (resolvedSource is List) {
          sourceList = resolvedSource;
        } else if (resolvedSource != null) {
          sourceList = [resolvedSource];
        }
      }
      // Case 2: If the current item already has this source (table inside listView)
      else if (resolved.state.itemData != null &&
          (resolved.state.itemData?[cleanKey] != null)) {
        final localSource = resolveValueRaw(
            "{{ $cleanKey }}", resolved.state.itemData,
            screenKey: resolved.screenKey);
        if (localSource is List) {
          sourceList = localSource;
        } else if (localSource != null) {
          sourceList = [localSource];
        }
      }
      // Case 3: Try modelMap first for named entities like 'stock', 'productVariant'
      else if (stateData?.modelMap != null &&
          stateData!.modelMap.containsKey(cleanKey)) {
        final localSource = stateData.modelMap[cleanKey];
        if (localSource is List) {
          sourceList = List<dynamic>.from(localSource as List);
        }
      }
      // Case 4: Fallback to resolving from rawState
      else if (stateData != null) {
        final localSource = resolveValueRaw(rowsKey, evalContext,
            screenKey: resolved.screenKey);
        if (localSource is List) {
          sourceList = localSource;
        } else if (localSource != null) {
          sourceList = [localSource];
        }
      }
    }

    if (sourceList.isEmpty) return const SizedBox.shrink();

    final rows = sourceList.asMap().entries.map((entry) {
      final rowItem = entry.value;

      // Build evaluation context for cell values
      // Uses evalContext as base, with row-specific 'item' and 'itemData' override
      final cellEvalContext = {
        ...evalContext,
        'item': rowItem,
        'itemData':
            rowItem is Map<String, dynamic> ? rowItem : null // Legacy support
      };

      return DigitTableRow(
        tableRow: rawColumns.asMap().entries.map((entry) {
          final colIndex = entry.key;
          final colConfig = entry.value;

          // Get the raw cellValue configuration
          // Resolve static localization keys from cellValue (text without {{}})
          final rawCellValue = colConfig['cellValue'] is String
              ? resolveStaticString(colConfig['cellValue'], localization)
              : colConfig['cellValue'];

          final cellValue = ConditionalEvaluator.evaluate(
              rawCellValue, cellEvalContext,
              screenKey: resolved.screenKey, stateData: stateData);

          // cellValue should already be resolved by ConditionalEvaluator
          // Just convert to string
          final finalText = cellValue?.toString() ?? '';

          final displayText = finalText != "null"
              ? (localization?.translate(finalText) ?? finalText)
              : "--";

          return DigitTableData(
            displayText,
            cellKey: rawCellValue is Map
                ? 'conditional_$colIndex'
                : rawCellValue?.toString() ?? '',
            widget: Text(
              displayText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      );
    }).toList();

    return _CustomDataTable(
      enableBorder: true,
      columns: columns,
      rows: rows,
    );
  }
}

class _CustomDataTable extends StatelessWidget {
  final List<DigitTableColumn> columns;
  final List<DigitTableRow> rows;
  final bool enableBorder;

  const _CustomDataTable({
    required this.columns,
    required this.rows,
    this.enableBorder = true,
  });

  double _columnWidth(Size screenSize) {
    if (AppView.isMobileView(screenSize)) return 140;
    if (AppView.isTabletView(screenSize)) return 170;
    return 202;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    final dividerColor = theme.colorTheme.generic.divider;
    final columnWidth = _columnWidth(MediaQuery.of(context).size);
    final tableWidth = columnWidth * columns.length;
    final outerBorderWidth = enableBorder ? 2.0 : 0.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: tableWidth + outerBorderWidth,
        decoration: BoxDecoration(
          border: enableBorder ? Border.all(color: dividerColor) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(context, textTheme, dividerColor, columnWidth),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      _buildDataRow(
                        context,
                        textTheme,
                        dividerColor,
                        columnWidth,
                        rows[i],
                        showBottomBorder: i != rows.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    DigitTextTheme textTheme,
    Color dividerColor,
    double columnWidth,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const DigitColors().light.genericBackground,
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: columns
              .map((column) => Container(
                    width: columnWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacer3,
                      vertical: spacer3,
                    ),
                    child: Text(
                      column.header,
                      softWrap: true,
                      style: textTheme.headingS.copyWith(
                        color: theme.colorTheme.primary.primary2,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    DigitTextTheme textTheme,
    Color dividerColor,
    double columnWidth,
    DigitTableRow row, {
    required bool showBottomBorder,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorTheme.paper.primary,
        border: showBottomBorder
            ? Border(bottom: BorderSide(color: dividerColor))
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < columns.length; i++)
              Container(
                width: columnWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: spacer3,
                  vertical: spacer3,
                ),
                child: Text(
                  i < row.tableRow.length ? row.tableRow[i].label : '',
                  softWrap: true,
                  style: textTheme.bodyS.copyWith(
                    color: theme.colorTheme.text.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
