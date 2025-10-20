# Loan Ranger - Application Blueprint

## 1. Overview

Loan Ranger is a specialized financial calculator for mortgage and real estate analysis for mobile and web. It combines the functions of a standard calculator with a powerful suite of tools for solving complex loan scenarios, calculating borrower qualifications, and analyzing different loan structures. The application is designed to be intuitive, responsive, and visually appealing, following modern design guidelines.

## 2. Architecture & Design

*   **Architecture**: The project will follow a feature-first layered architecture to ensure separation of concerns and scalability.
    *   `lib/src/features`: Each core feature (e.g., `calculator`, `amortization`, `qualification`) will have its own directory containing its presentation (widgets), domain (logic), and data layers.
    *   `lib/src/core`: Shared utilities, models, and services.
    *   `lib/src/theme`: Centralized theme and styling definitions.
*   **State Management**: We will use the `provider` package for state management and dependency injection, which is suitable for the complexity of the application state.
*   **UI/UX**:
    *   **Design**: Modern Material 3 design with a focus on clarity and ease of use.
    *   **Theming**: A consistent theme will be established using `ColorScheme.fromSeed` and custom fonts from `google_fonts`. The app will support both light and dark modes.
    *   **Responsiveness**: The UI will be fully responsive to work seamlessly on both mobile devices and web browsers.

## 3. Development Plan

### Phase 1: Core Calculator (MVP) - COMPLETED

1.  **Project Setup**: **Done**
2.  **Theming & Layout**: **Done**
3.  **Core Logic**: **Done**

### Phase 1a: Arithmetic Operations

1.  **Provider Enhancement**: Update `CalculatorProvider` to handle arithmetic operations (+, -, *, /).
2.  **State Management**: Add state to manage the current operation and the first operand.
3.  **UI Integration**: Connect the arithmetic buttons to the new provider methods.
4.  **Testing**: Write widget tests to verify the arithmetic operations.

### Phase 2: PITI & Secondary Features

1.  **State Expansion**: Extend the `CalculatorProvider` to include state for `price`, `downPayment`, PITI components (`propertyTax`, `homeInsurance`, etc.), and `monthlyExpenses`.
2.  **PITI Toggle**: Implement the logic to toggle the main payment display between P&I and the full PITI payment.
3.  **Down Payment Calculation**: Implement automatic `loanAmount` calculation when `price` and `downPayment` are entered.

### Phase 3: Loan Analysis Tools

1.  **Amortization**:
    *   Create a new screen to display the amortization schedule.
    *   Implement the logic to generate the schedule data.
2.  **Remaining Balance**: Implement the function to calculate the loan balance after a specified period.
3.  **Bi-Weekly Payments**: Implement the bi-weekly conversion feature and display the interest savings.

### Phase 4: Qualification Suite

1.  **State & UI**: Create a `QualificationProvider` and a dedicated UI section for managing qualifying ratios, income, and debt.
2.  **Calculations**: Implement the logic to calculate the maximum qualifying loan amount and the minimum income required.

### Phase 5: Advanced Features & Refinement

1.  **ARM Calculations**: Implement the functionality for Adjustable-Rate Mortgages.
2.  **Specialized Metrics**: Add features for APR, Future Value, Odd Days Interest, and "After-Tax" payment estimation.
3.  **Polish**: Refine the UI, add animations, and ensure full keyboard support.
4.  **Testing**: Write unit and widget tests for core logic and UI components.
