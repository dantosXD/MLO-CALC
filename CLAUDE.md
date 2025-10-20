# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Loan Ranger** is a specialized financial calculator Flutter application for mortgage and real estate analysis, supporting both mobile and web platforms. The app combines standard calculator functionality with powerful financial tools for loan calculations, borrower qualifications, and amortization analysis. Design is inspired by professional-grade physical calculators like the Calculated Industries Qualifier Plus IIx.

### Core Capability
The primary goal is to calculate any one of the four core loan variables (Loan Amount, Interest Rate, Term, or Payment) when the other three are known, plus extended functionality for deep analysis of loan costs and schedules.

## Development Commands

### Running the Application
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on web browser
flutter run -d linux-desktop   # Run on Linux desktop
```

### Testing
```bash
flutter test                              # Run all tests
flutter test test/widget_test.dart        # Run specific test file
flutter test --coverage                   # Run tests with coverage
```

### Building
```bash
flutter build apk              # Build Android APK
flutter build web              # Build for web
flutter build linux            # Build for Linux desktop
```

### Linting and Analysis
```bash
flutter analyze                # Run static analysis
dart format lib/ test/         # Format code
```

### Dependencies
```bash
flutter pub get                # Install dependencies
flutter pub upgrade            # Upgrade dependencies
```

## Architecture

### State Management
The application uses the **Provider** package for state management:
- **ThemeProvider** (lib/main.dart:20-29): Manages light/dark theme toggling
- **CalculatorProvider** (lib/src/providers/calculator_provider.dart): Core calculator logic, handles both arithmetic operations and financial calculations

#### State Variables to Track
The CalculatorProvider will need to manage:

**Primary Loan Variables:**
- `loanAmount`, `interestRate`, `termYears`, `payment`

**Secondary & PITI Variables:**
- `price`, `downPayment`
- `propertyTax`, `homeInsurance`, `mortgageInsurance` (annual amounts)
- `monthlyExpenses` (other monthly costs like HOA)

**Qualification Variables:**
- `qualRatio1`, `qualRatio2` (storing income:debt ratio pairs like 28:36 and 29:41)
- `annualIncome`, `monthlyDebt`

**Operational State:**
- `displayValue`, `activeAction` (currently targeted financial variable)
- `firstOperand`, `operator`, `waitingForSecondOperand` (arithmetic operations)
- `displayMode` (toggle between 'pi' and 'piti' payment display)
- `amortizationData`, `futureValue`, `loanFees`, `armAdjustment`, `armLifetimeCap`

### Key Design Patterns

1. **Dual-Input-Flow Number Entry**:
   - Flow 1: Type number → press function key (e.g., `350000` → `[L/A]`)
   - Flow 2: Press function key → type number (managed by `activeAction` state)

2. **Dual-Mode Calculator**: The calculator operates in two modes:
   - **Arithmetic mode**: Standard calculator operations (+, -, x, /)
   - **Financial mode**: Mortgage calculations using Loan Amount, Interest Rate, and Term
   - When switching from financial to arithmetic mode, financial state is cleared (lib/src/providers/calculator_provider.dart:88-93)

3. **Financial Calculation Logic**:
   - Solves for missing variable when 3 of 4 are provided (Loan Amount, Interest Rate, Term, Payment)
   - Payment calculation uses standard amortization formula: M = P * [r(1+r)^n] / [(1+r)^n - 1]
   - Located in lib/src/providers/calculator_provider.dart:160-223

4. **Display Reset Behavior**: Uses `_shouldResetDisplay` flag to handle display clearing after operations and financial inputs

5. **PITI Toggle Pattern**: After P&I payment is calculated, pressing `[Pmt]` again toggles display to show full PITI payment
   - Formula: `PITI = payment + (propertyTax/12) + (homeInsurance/12) + (mortgageInsurance/12) + monthlyExpenses`

6. **Down Payment Heuristic**: Values under 100 are treated as percentages, otherwise as flat amounts

### Project Structure
```
lib/
  main.dart                              # App entry point, theme setup, main calculator UI
  src/
    providers/
      calculator_provider.dart           # Core calculation logic and state
    widgets/
      calculator_button.dart             # Reusable calculator button widget
```

### Theming
- Material 3 design with ColorScheme.fromSeed (seed: Colors.blueGrey)
- Google Fonts integration: Oswald (display), Roboto Condensed (titles), Roboto (body)
- Full light/dark mode support

## Testing Guidelines

### Widget Test Structure
Tests use a helper function `createTestableWidget()` to wrap the app in necessary providers (test/widget_test.dart:9-17). The display text widget is identified using `ValueKey('display')` for reliable testing.

### Running Specific Tests
```bash
flutter test --name "Arithmetic operations"  # Run tests matching pattern
flutter test --plain-name "Addition"         # Run exact match
```

## Development Roadmap

Current implementation status (see blueprint.md for details):
- **Phase 1 (COMPLETED)**: Core calculator with basic display and inputs
- **Phase 1a (COMPLETED)**: Arithmetic operations
- **Phase 2-5 (PENDING)**: PITI calculations, amortization schedules, qualification suite, ARM calculations

### Feature Implementation Guide

#### Core Calculator Functions (Phase 2)
1. **PITI Toggle**: Press `[Pmt]` after calculation to toggle between P&I and full PITI payment display
2. **Auto Down Payment**: When `price` and `downPayment` entered, auto-calculate `loanAmount`

#### Loan Analysis Features (Phase 3)
1. **Amortization Schedule**: Month-by-month breakdown showing principal, interest, payment, remaining balance
   - Initialize `currentBalance = loanAmount`
   - For each month: calculate `interestPaid = currentBalance * r`, `principalPaid = M - interestPaid`
   - Final payment adjusted to clear remaining balance precisely

2. **Balloon Payments (Remaining Balance)**: Enter years → press `[Balance]` to show remaining principal after that period

3. **Bi-Weekly Conversion**:
   - Divide monthly payment by 2, calculate new term based on 26 payment periods/year
   - Display total interest saved vs original monthly schedule

4. **ARM Calculations**:
   - User inputs rate change and time period (e.g., 1% every 1 year)
   - Re-amortize remaining balance at new rate over remaining term
   - Support both increasing and decreasing rates
   - Enforce lifetime interest rate cap if set

#### Specialized Financial Metrics (Phase 5)
1. **APR**: Re-calculate effective interest rate including points and fees
2. **Future Value**: Calculate property appreciation based on rate and term
3. **Odd Days Interest**: Calculate prepaid simple interest for days between closing and first payment
4. **After-Tax Payment**: Estimate monthly payment after tax deductions based on user's tax bracket

#### Borrower Qualification Suite (Phase 4)
1. **Qualifying Ratios**: Store two ratio sets via `[Qual 1]` and `[Qual 2]` keys (e.g., 28:36, 29:41)
2. **Maximum Loan Amount**:
   - Input: income, debt, expenses, rate, term
   - Calculate max PITI from both front-end (housing) and back-end (total debt) ratios
   - Use more restrictive result, solve for loan amount
3. **Minimum Income**:
   - Input: desired loan amount, rate, term, debt
   - Calculate PITI, determine minimum income to meet qualifying ratios

## Core Financial Formulas

Let: P = Loan Amount, M = Monthly Payment, r = Monthly Interest Rate (annual/100/12), n = Total Payments (years*12)

1. **Calculate Monthly Payment (M)**
   ```
   M = P * [r(1+r)^n] / [(1+r)^n - 1]
   ```

2. **Calculate Loan Amount (P)**
   ```
   P = M * [(1+r)^n - 1] / [r(1+r)^n]
   ```

3. **Calculate Term (n months)**
   ```
   n = -ln(1 - P*r/M) / ln(1+r)
   Edge case: If P*r ≥ M, loan will never be paid off (show error)
   ```

4. **Calculate Interest Rate (r)**: Not yet implemented - requires iterative solving (Newton's method)

## Important Notes

- Financial calculations assume monthly payment frequency (converted from annual rate and term in years)
- Interest rate is stored as percentage (e.g., 5.0 for 5%), converted to decimal in calculations
- Rate calculation (solving for interest rate) is not yet implemented (lib/src/providers/calculator_provider.dart:175)
- Division by zero displays "Error" and resets arithmetic state
- All annual amounts (property tax, insurance) are divided by 12 for monthly PITI calculation
- Amortization final payment must be adjusted to clear remaining balance precisely (avoid rounding errors)
