import 'package:expense_tracker_codsoft/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  final List<Expense> _allExpenses = [];

/*
  setup
  */
  //initialize db
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ExpenseSchema],
      directory: dir.path,
    );
  }

/*
Getters
 */
  List<Expense> get allExpenses => _allExpenses;

/*
Operations
 */
//Create - add a new expense
  Future<void> createNewExpense(Expense newExpense) async {
    // add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));
    // re_read from db
    await readExpense();
  }

// Read - expense from db
  Future<void> readExpense() async {
    // fetch all existing expenses from db
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    // give to local expense list
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);
    // update UI
    notifyListeners();
  }

// Update - edit an expense in db
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    // make sure new expense has same id as existing one
    updatedExpense.id = id;
    // update in db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));
    // re_read from db

    await readExpense();
  }

  //Delete - an expense
  Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() => isar.expenses.delete(id));
    // re_read from db
    await readExpense();
  }

  void addExpense(Expense expense) {
    _allExpenses.add(expense);
  }

/*
Helper
 */

// calculate total expenses for each month
  /*
  {

  }
   */

  Future<Map<String, double>> calculateMonthlyTotals() async {
    // ensure the expenses are read from the db
    await readExpense();
    // create a map to keep track of total expenses per month, year
    Map<String, double> monthlyTotals = {};
    // iterate over all expense
    for (var expense in _allExpenses) {
      // extratch the year & month from the data of the expense
      String yearMonth = '${expense.date.year}-${expense.date.month}';

// if the year-month is not yet in the map, initialize to 0
      if (!monthlyTotals.containsKey(yearMonth)) {
        monthlyTotals[yearMonth] = 0;
      }
      // add the expense amount to the total for the month
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount;
    }
    return monthlyTotals;
  }

  // calculate current month total
  Future<double> calculateCurrentMonthTotal() async {
    // ensure expenses are read from db first
    await readExpense();
    // get current month, year
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    // filter the expense to include only those for this month this year
    List<Expense> currentMonthExpense = _allExpenses.where((expense) {
      return expense.date.month == currentMonth &&
          expense.date.year == currentYear;
    }).toList();
    // calculate total amount for the current month
    double total =
        currentMonthExpense.fold(0, (sum, expense) => sum + expense.amount);
    return total;
  }

  // get start month
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now()
          .month; // default to current month is no expense are recorded
    }
    // sort expenses by date to find the earliest
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );
    return _allExpenses.first.date.month;
  }

  // get start year
  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now()
          .year; // default to current year is no expense are recorded
    }
    // sort expenses by date to find the earliest
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );
    return _allExpenses.first.date.year;
  }
}
