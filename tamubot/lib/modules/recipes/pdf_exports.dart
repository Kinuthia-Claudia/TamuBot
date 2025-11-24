// lib/utils/pdf_export.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tamubot/modules/recipes/mealplan_model.dart';

class PdfExportService {
  static Future<void> exportMealPlanToPdf(MealPlan mealPlan) async {
    final pdf = pw.Document();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final mealTypes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0, 
                child: pw.Text(
                  mealPlan.name,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              
              if (mealPlan.description != null && mealPlan.description!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  mealPlan.description!,
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                ),
              ],
              
              pw.SizedBox(height: 20),
              
              // Create table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Day', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      for (var mealType in mealTypes)
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(mealType, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                    ],
                  ),
                  // Data rows
                  for (var dayIndex in mealPlan.selectedDays)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(dayNames[dayIndex]),
                        ),
                        for (var mealType in mealTypes)
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              _getMealForDayAndType(mealPlan, dayIndex, mealType),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save and share the PDF
    await _saveAndSharePdf(pdf, mealPlan.name);
  }

  static String _getMealForDayAndType(MealPlan mealPlan, int dayIndex, String mealType) {
    try {
      final dayMeals = mealPlan.dailyMeals[dayIndex] ?? [];
      final meal = dayMeals.firstWhere(
        (meal) => meal.mealType.toLowerCase() == mealType.toLowerCase(),
      );
      
      // Use safe access to displayName
      if (meal.displayName.isNotEmpty) {
        return meal.displayName;
      } else {
        return '-';
      }
    } catch (e) {
      return '-'; // Return dash when no meal is found
    }
  }

  static Future<void> _saveAndSharePdf(pw.Document pdf, String fileName) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf');
      
      // Save the PDF file
      await file.writeAsBytes(await pdf.save());
      
      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Meal Plan: $fileName',
      );
      
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }
}