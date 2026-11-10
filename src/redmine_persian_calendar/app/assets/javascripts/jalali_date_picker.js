/**
 * Enhanced Jalali Date Picker for Redmine
 * Complete rewrite with proper positioning, working year/month selectors, and beautiful UI
 * Maintains Gregorian server values while providing Persian calendar interface
 */

// Persian calendar constants
const PERSIAN_MONTHS = [
  "فروردین",
  "اردیبهشت",
  "خرداد",
  "تیر",
  "مرداد",
  "شهریور",
  "مهر",
  "آبان",
  "آذر",
  "دی",
  "بهمن",
  "اسفند",
];

const PERSIAN_WEEKDAYS = [
  "شنبه",
  "یکشنبه",
  "دوشنبه",
  "سه‌شنبه",
  "چهارشنبه",
  "پنج‌شنبه",
  "جمعه",
];

const PERSIAN_WEEKDAYS_SHORT = ["ش", "ی", "د", "س", "چ", "پ", "ج"];

// Enhanced Jalali Date Picker Class
class JalaliDatePicker {
  constructor(inputElement, options = {}) {
    this.input = inputElement;

    // Prevent duplicate initialization
    if (JalaliDatePicker.hasPickerFor(inputElement)) {
      return;
    }

    this.options = {
      onDateSelect: options.onDateSelect || null,
      showTodayButton: options.showTodayButton !== false,
      ...options,
    };

    this.isOpen = false;
    this.currentDate = new Date();
    this.selectedDate = null;
    this.showYearSelect = false;
    this.showMonthSelect = false;
    this.yearRange = { start: 1300, end: 1450 }; // Persian years

    this.init();
  }

  init() {
    this.createPickerHTML();
    this.attachEventListeners();
    this.initializeFromInput();
    this.updateInputValue();
  }

  createPickerHTML() {
    // Check if this input already has a Jalali picker
    if (
      this.input.nextElementSibling &&
      this.input.nextElementSibling.classList.contains(
        "jalali-date-picker-container",
      )
    ) {
      return;
    }

    // Create picker container
    this.pickerContainer = document.createElement("div");
    this.pickerContainer.className = "jalali-date-picker-container";
    this.pickerContainer.style.cssText = `
      position: relative;
      display: inline-block;
      direction: rtl;
      width: 100%;
      max-width: 300px;
    `;

    // Create trigger button with better styling
    this.triggerButton = document.createElement("button");
    this.triggerButton.type = "button";
    this.triggerButton.className = "jalali-date-picker-trigger";
    this.triggerButton.style.cssText = `
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      min-width: 220px;
      padding: 10px 14px;
      border: 2px solid #ddd;
      border-radius: 8px;
      background: white;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.3s ease;
      font-family: inherit;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    `;

    // Create calendar icon with better styling
    const calendarIcon = document.createElement("span");
    calendarIcon.innerHTML = "&#128197;"; // Calendar emoji as HTML entity
    calendarIcon.style.cssText = `
      margin-left: 8px;
      font-size: 16px;
      opacity: 0.7;
    `;

    // Create text span
    const textSpan = document.createElement("span");
    textSpan.textContent = "انتخاب تاریخ";
    textSpan.style.cssText = `
      flex: 1;
      text-align: right;
      color: #333;
      font-family: "Vazirmatn FD NL", Tahoma, Arial, sans-serif;
    `;

    this.triggerButton.appendChild(textSpan);
    this.triggerButton.appendChild(calendarIcon);

    // Create clear button
    this.clearButton = document.createElement("button");
    this.clearButton.type = "button";
    this.clearButton.className = "jalali-date-picker-clear";
    this.clearButton.innerHTML = "&#10005;"; // X symbol as HTML entity
    this.clearButton.title = "پاک کردن تاریخ";
    this.clearButton.style.cssText = `
      display: none;
      align-items: center;
      justify-content: center;
      width: 28px;
      height: 28px;
      margin-right: 5px;
      padding: 0;
      border: 1px solid #ddd;
      border-radius: 4px;
      background: #f5f5f5;
      color: #666;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
    `;

    // Create dropdown with better positioning
    this.dropdown = document.createElement("div");
    this.dropdown.className = "jalali-date-picker-dropdown";

    this.pickerContainer.appendChild(this.triggerButton);
    this.pickerContainer.appendChild(this.clearButton);

    // Insert after the original input
    this.input.parentNode.insertBefore(
      this.pickerContainer,
      this.input.nextSibling,
    );

    // Hide original input
    this.input.style.display = "none";

    // Mark input as having Jalali picker
    this.input.setAttribute("data-jalali-picker", "true");
  }

  attachEventListeners() {
    // Toggle picker
    this.triggerButton.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.toggle();
    });

    // Clear button functionality
    this.clearButton.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.clearDate();
    });

    // Hover effects for clear button
    this.clearButton.addEventListener("mouseenter", () => {
      this.clearButton.style.background = "#e74c3c";
      this.clearButton.style.color = "white";
      this.clearButton.style.borderColor = "#c0392b";
    });

    this.clearButton.addEventListener("mouseleave", () => {
      this.clearButton.style.background = "#f5f5f5";
      this.clearButton.style.color = "#666";
      this.clearButton.style.borderColor = "#ddd";
    });

    // Close on outside click - Fixed to handle year/month selectors
    document.addEventListener("click", (e) => {
      if (
        !this.pickerContainer.contains(e.target) &&
        !this.dropdown.contains(e.target) &&
        !e.target.closest(".year-month-selector") &&
        !e.target.classList.contains("year-selector") &&
        !e.target.classList.contains("month-selector") &&
        !e.target.classList.contains("year-option") &&
        !e.target.classList.contains("month-option") &&
        !e.target.classList.contains("close-selector")
      ) {
        this.close();
      }
    });

    // Close on escape key
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && this.isOpen) {
        this.close();
      }
    });

    // Hover effects for trigger button
    this.triggerButton.addEventListener("mouseenter", () => {
      if (!this.isOpen) {
        this.triggerButton.style.borderColor = "#007cba";
        this.triggerButton.style.boxShadow = "0 4px 8px rgba(0,124,186,0.2)";
      }
    });

    this.triggerButton.addEventListener("mouseleave", () => {
      if (!this.isOpen) {
        this.triggerButton.style.borderColor = "#ddd";
        this.triggerButton.style.boxShadow = "0 2px 4px rgba(0,0,0,0.1)";
      }
    });
  }

  toggle() {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.isOpen = true;

    // Clean up any existing dropdown in body first
    const existingDropdowns = document.querySelectorAll(
      ".jalali-date-picker-dropdown",
    );
    existingDropdowns.forEach((dropdown) => {
      if (
        dropdown.parentElement === document.body &&
        dropdown !== this.dropdown
      ) {
        document.body.removeChild(dropdown);
      }
    });

    // Append dropdown to document body to avoid overflow issues
    document.body.appendChild(this.dropdown);

    // Force all styles inline to override any CSS conflicts - Simple Redmine style
    this.dropdown.style.cssText = `
      position: fixed !important;
      z-index: 2147483647 !important;
      width: 280px !important;
      background: white !important;
      border: 1px solid #ccc !important;
      border-radius: 3px !important;
      box-shadow: 0 2px 8px rgba(0,0,0,0.15) !important;
      display: block !important;
      visibility: visible !important;
      opacity: 1 !important;
      pointer-events: auto !important;
      overflow: hidden !important;
      max-height: none !important;
      transform: none !important;
      font-family: "Vazirmatn FD NL", Verdana, sans-serif !important;
      direction: rtl !important;
      font-size: 11px !important;
      font-family: "Vazirmatn FD NL", Tahoma, "Segoe UI", Arial, sans-serif !important;
      -webkit-font-feature-settings: "liga" off !important;
      font-feature-settings: "liga" off !important;
    `;

    this.dropdown.classList.add("visible");
    // Render first so the dropdown has its real size before measuring it.
    this.renderCalendar();
    this.positionDropdown();

    // Keep the dropdown glued to its trigger while the page scrolls or resizes.
    if (!this._reposition) {
      this._reposition = () => {
        if (this.isOpen) this.positionDropdown();
      };
    }
    window.addEventListener("scroll", this._reposition, true);
    window.addEventListener("resize", this._reposition);

    this.triggerButton.style.borderColor = "#007cba";

    // Force a repaint
    this.dropdown.offsetHeight;
  }

  close() {
    this.isOpen = false;

    if (this._reposition) {
      window.removeEventListener("scroll", this._reposition, true);
      window.removeEventListener("resize", this._reposition);
    }

    if (this.dropdown) {
      this.dropdown.style.display = "none";
      this.dropdown.classList.remove("visible");

      // Remove dropdown from body if it's there
      if (this.dropdown.parentElement === document.body) {
        document.body.removeChild(this.dropdown);
      }
    }

    this.showYearSelect = false;
    this.showMonthSelect = false;
    this.triggerButton.style.borderColor = "#ddd";
  }

  positionDropdown() {
    const dd = this.dropdown;
    if (!dd || !this.triggerButton) return;

    const margin = 8;
    const rect = this.triggerButton.getBoundingClientRect();
    // Measure the real rendered size instead of guessing; a wrong guess is
    // what shoved the calendar far away from its field.
    const w = dd.offsetWidth || 280;
    const h = dd.offsetHeight || 360;
    const vw = window.innerWidth;
    const vh = window.innerHeight;

    // Vertical: prefer just below the field, flip above only if it doesn't fit.
    let top = rect.bottom + 6;
    if (top + h > vh - margin) {
      const above = rect.top - h - 6;
      top = above >= margin ? above : Math.max(margin, vh - h - margin);
    }
    if (top < margin) top = margin;

    // Horizontal: RTL — align the dropdown's right edge with the field's right
    // edge, then clamp inside the viewport.
    let left = rect.right - w;
    if (left + w > vw - margin) left = vw - w - margin;
    if (left < margin) left = margin;

    dd.style.setProperty("position", "fixed", "important");
    dd.style.setProperty("top", `${Math.round(top)}px`, "important");
    dd.style.setProperty("left", `${Math.round(left)}px`, "important");
    dd.style.setProperty("right", "auto", "important");
    dd.style.setProperty("bottom", "auto", "important");
    dd.style.setProperty("margin", "0", "important");
    dd.style.setProperty("transform", "none", "important");
    dd.style.setProperty("z-index", "2147483647", "important");
  }

  renderCalendar() {
    const currentJalali = this.gregorianToJalali(this.currentDate);

    // Determine what view to show based on state
    let bodyContent = "";

    if (this.showYearSelect) {
      // Show year selection view
      bodyContent = this.renderYearSelector(currentJalali);
    } else if (this.showMonthSelect) {
      // Show month selection view
      bodyContent = this.renderMonthSelector(currentJalali);
    } else {
      // Show normal calendar view
      bodyContent = this.renderCalendarView(currentJalali);
    }

    this.dropdown.innerHTML = `
      <div class="jalali-picker-header" style="
        background: #628db6;
        color: white;
        padding: 8px;
        border-bottom: 1px solid #ccc;
      ">
        <div class="jalali-picker-nav" style="
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 8px;
        ">
          <button type="button" class="nav-btn next-month" style="
            background: none;
            border: 1px solid rgba(255,255,255,0.3);
            color: white;
            padding: 4px 8px;
            cursor: pointer;
            font-size: 12px;
          ">&lt;</button>
          
          <div class="date-selectors" style="display: flex; gap: 4px;">
            <button type="button" class="year-selector" style="
              background: ${
                this.showYearSelect ? "rgba(255,255,255,0.2)" : "none"
              };
              border: 1px solid rgba(255,255,255,0.5);
              color: white;
              padding: 4px 8px;
              cursor: pointer;
              font-size: 11px;
              border-radius: 3px;
              transition: all 0.2s ease;
              font-weight: ${this.showYearSelect ? "bold" : "normal"};
              box-shadow: ${
                this.showYearSelect ? "0 1px 3px rgba(0,0,0,0.2)" : "none"
              };
            ">${currentJalali.year}</button>
            
            <button type="button" class="month-selector" style="
              background: ${
                this.showMonthSelect ? "rgba(255,255,255,0.2)" : "none"
              };
              border: 1px solid rgba(255,255,255,0.5);
              color: white;
              padding: 4px 8px;
              cursor: pointer;
              font-size: 11px;
              border-radius: 3px;
              transition: all 0.2s ease;
              font-weight: ${this.showMonthSelect ? "bold" : "normal"};
              box-shadow: ${
                this.showMonthSelect ? "0 1px 3px rgba(0,0,0,0.2)" : "none"
              };
            ">${PERSIAN_MONTHS[currentJalali.month - 1]}</button>
          </div>
          
          <button type="button" class="nav-btn prev-month" style="
            background: none;
            border: 1px solid rgba(255,255,255,0.3);
            color: white;
            padding: 4px 8px;
            cursor: pointer;
            font-size: 12px;
          ">&gt;</button>
        </div>
        
        ${
          !this.showYearSelect && !this.showMonthSelect
            ? `
        <div class="weekdays" style="
          display: grid;
          grid-template-columns: repeat(7, 1fr);
          gap: 0;
          border: 1px solid #ddd;
          border-bottom: none;
        ">
          ${PERSIAN_WEEKDAYS_SHORT.map(
            (day) =>
              `<div style="
                text-align: center; 
                font-size: 10px; 
                padding: 4px;
                background: #f0f0f0;
                color: #333;
                border: 1px solid #ddd;
                border-top: none;
                border-left: none;
                font-weight: bold;
              ">${day}</div>`,
          ).join("")}
        </div>
        `
            : ""
        }
      </div>
      
      <div class="jalali-picker-body" style="
        padding: 8px;
        background: white;
        min-height: 200px;
      ">
        ${bodyContent}
      </div>
    `;

    this.attachCalendarEventListeners();

    // Auto-scroll to current year in year selector (FIXED)
    if (this.showYearSelect) {
      setTimeout(() => {
        const currentJalali = this.gregorianToJalali(this.currentDate);
        const currentYearButton = this.dropdown.querySelector(
          `[data-year="${currentJalali.year}"]`,
        );
        if (currentYearButton) {
          currentYearButton.scrollIntoView({
            behavior: "smooth",
            block: "center",
          });
        }
      }, 100);
    }
  }

  renderCalendarView(currentJalali) {
    return `
      <div class="calendar-grid" style="
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        gap: 0;
        border: 1px solid #ddd;
      ">
        ${this.generateCalendarDays(currentJalali)
          .map((day) => this.renderCalendarDay(day, currentJalali))
          .join("")}
      </div>
      
      ${
        this.options.showTodayButton
          ? `
        <div style="
          text-align: center; 
          margin-top: 8px; 
          padding-top: 8px; 
          border-top: 1px solid #ddd;
          display: flex;
          justify-content: center;
          gap: 8px;
        ">
          <button type="button" class="today-btn" style="
            background: #628db6;
            color: white;
            border: 1px solid #5a7fa6;
            padding: 4px 12px;
            cursor: pointer;
            font-size: 11px;
            border-radius: 3px;
            transition: all 0.2s ease;
          ">امروز</button>
          <button type="button" class="clear-btn" style="
            background: #dc3545;
            color: white;
            border: 1px solid #c82333;
            padding: 4px 12px;
            cursor: pointer;
            font-size: 11px;
            border-radius: 3px;
            transition: all 0.2s ease;
          ">پاک کردن</button>
        </div>
      `
          : ""
      }
    `;
  }

  renderYearSelector(currentJalali) {
    return `
      <div style="text-align: center; margin-bottom: 12px;">
        <h3 style="margin: 0; color: #628db6; font-size: 12px; font-family: \"Vazirmatn FD NL\", Tahoma, Arial, sans-serif;">انتخاب سال</h3>
        <button type="button" class="back-to-calendar" style="
          background: #f5f5f5;
          border: 1px solid #ccc;
          padding: 4px 8px;
          cursor: pointer;
          font-size: 11px;
          color: #666;
          margin-top: 4px;
        ">بازگشت به تقویم</button>
      </div>
      <div class="year-grid" style="
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 4px;
        max-height: 200px;
        overflow-y: auto;
        padding: 4px;
        border: 1px solid #ddd;
        background: white;
      ">
        ${this.generateYearOptions(currentJalali.year)}
      </div>
    `;
  }

  renderMonthSelector(currentJalali) {
    return `
      <div style="text-align: center; margin-bottom: 12px;">
        <h3 style="margin: 0; color: #628db6; font-size: 12px; font-family: \"Vazirmatn FD NL\", Tahoma, Arial, sans-serif;">انتخاب ماه</h3>
        <button type="button" class="back-to-calendar" style="
          background: #f5f5f5;
          border: 1px solid #ccc;
          padding: 4px 8px;
          cursor: pointer;
          font-size: 11px;
          color: #666;
          margin-top: 4px;
        ">بازگشت به تقویم</button>
      </div>
      <div class="month-grid" style="
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 6px;
        padding: 8px;
        max-width: 100%;
        overflow: hidden;
        box-sizing: border-box;
        justify-items: center;
        align-items: center;
      ">
        ${this.generateMonthOptions()}
      </div>
    `;
  }

  generateCalendarDays(currentJalali) {
    const daysInMonth = this.getJalaliMonthDays(
      currentJalali.year,
      currentJalali.month,
    );
    const firstDayOfMonth = this.getFirstDayOfJalaliMonth(
      currentJalali.year,
      currentJalali.month,
    );
    const days = [];

    // Add empty cells for days before the first day of month
    for (let i = 0; i < firstDayOfMonth; i++) {
      days.push(null);
    }

    // Add the days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      days.push(day);
    }

    // Complete the grid (42 cells for 6 weeks)
    while (days.length < 42) {
      days.push(null);
    }

    return days;
  }

  renderCalendarDay(day, currentJalali) {
    if (day === null) {
      return `<div style="
        height: 28px;
        border: 1px solid #ddd;
        border-top: none;
        border-left: none;
        background: #f9f9f9;
      "></div>`;
    }

    const isSelected =
      this.selectedDate &&
      this.selectedDate.year === currentJalali.year &&
      this.selectedDate.month === currentJalali.month &&
      this.selectedDate.day === day;

    // Debug logging for selection
    if (isSelected) {
    }

    const isToday = this.isTodayJalali(
      currentJalali.year,
      currentJalali.month,
      day,
    );

    let dayStyle = `
      height: 28px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      font-size: 11px;
      border: 1px solid #ddd;
      border-top: none;
      border-left: none;
      background: white;
      color: #333;
      font-family: "Vazirmatn FD NL", Verdana, sans-serif;
    `;

    let dayClasses = "calendar-day";

    if (isSelected) {
      dayClasses += " selected";
      dayStyle += `
        background: #628db6 !important;
        color: white !important;
        font-weight: bold !important;
        box-shadow: 0 2px 4px rgba(98, 141, 182, 0.3) !important;
      `;
    } else if (isToday) {
      dayClasses += " today";
      dayStyle += `
        background: #e6f3ff !important;
        color: #628db6 !important;
        font-weight: bold !important;
      `;
    }

    const hoverEffect = isSelected
      ? ""
      : `
      onmouseover="
        if (!this.classList.contains('selected')) {
          this.style.background = '#f0f8ff';
          this.style.color = '#628db6';
        }
      "
      onmouseout="
        if (!this.classList.contains('selected')) {
          this.style.background = 'white';
          this.style.color = '#333';
        }
      "
    `;

    return `
      <button type="button" class="${dayClasses}" data-day="${day}" style="${dayStyle}" ${hoverEffect}>
        ${day}
      </button>
    `;
  }

  attachCalendarEventListeners() {
    // Navigation buttons - only work in calendar view
    if (!this.showYearSelect && !this.showMonthSelect) {
      const nextBtn = this.dropdown.querySelector(".next-month");
      const prevBtn = this.dropdown.querySelector(".prev-month");

      nextBtn?.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.navigateMonth(1);
      });

      prevBtn?.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.navigateMonth(-1);
      });

      // Day selection - only in calendar view
      const dayButtons = this.dropdown.querySelectorAll(".calendar-day");
      dayButtons.forEach((btn) => {
        btn.addEventListener("click", (e) => {
          e.preventDefault();
          e.stopPropagation();
          const day = parseInt(btn.dataset.day);
          this.selectDate(day);
        });
      });

      // Today button - only in calendar view
      const todayBtn = this.dropdown.querySelector(".today-btn");
      todayBtn?.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.selectToday();
      });

      // Clear button - only in calendar view
      const clearBtn = this.dropdown.querySelector(".clear-btn");
      clearBtn?.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.clearDate();
      });
    }

    // Year/Month selectors - always available
    const yearSelector = this.dropdown.querySelector(".year-selector");
    const monthSelector = this.dropdown.querySelector(".month-selector");

    yearSelector?.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.showYearSelect = true;
      this.showMonthSelect = false;
      this.renderCalendar();
    });

    monthSelector?.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.showYearSelect = false;
      this.showMonthSelect = true;
      this.renderCalendar();
    });

    // Back to calendar button - in year/month views
    const backBtn = this.dropdown.querySelector(".back-to-calendar");
    backBtn?.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.showYearSelect = false;
      this.showMonthSelect = false;
      this.renderCalendar();
    });

    // Year options - in year view
    const yearButtons = this.dropdown.querySelectorAll(".year-option");
    yearButtons.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        const selectedYear = parseInt(btn.dataset.year);
        this.changeYear(selectedYear);
        // Switch to month view after year selection
        this.showYearSelect = false;
        this.showMonthSelect = true;
        this.renderCalendar();
      });
    });

    // Month options - in month view
    const monthButtons = this.dropdown.querySelectorAll(".month-option");
    monthButtons.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        const selectedMonth = parseInt(btn.dataset.month);
        this.changeMonth(selectedMonth);
        // Switch back to calendar view after month selection
        this.showYearSelect = false;
        this.showMonthSelect = false;
        this.renderCalendar();
      });
    });
  }

  navigateMonth(direction) {
    const currentJalali = this.gregorianToJalali(this.currentDate);
    let newMonth = currentJalali.month + direction;
    let newYear = currentJalali.year;

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    this.currentDate = this.jalaliToGregorian(newYear, newMonth, 1);
    this.renderCalendar();
  }

  selectDate(day) {
    const currentJalali = this.gregorianToJalali(this.currentDate);
    this.selectedDate = {
      year: currentJalali.year,
      month: currentJalali.month,
      day: day,
    };

    // Convert to Gregorian for the input value
    const gregorianDate = this.jalaliToGregorian(
      this.selectedDate.year,
      this.selectedDate.month,
      this.selectedDate.day,
    );

    // Re-render calendar to show selection, then close after brief delay
    this.renderCalendar();

    setTimeout(() => {
      this.updateInputValue();
      this.close();

      // Call callback if provided
      if (this.options.onDateSelect) {
        this.options.onDateSelect({
          jalali: this.selectedDate,
          gregorian: gregorianDate,
          formatted: this.formatJalaliDate(this.selectedDate),
        });
      }
    }, 200); // Brief delay to show selection
  }

  selectToday() {
    const today = new Date();
    const todayJalali = this.gregorianToJalali(today);

    this.selectedDate = todayJalali;
    this.currentDate = today;

    // Re-render calendar to show selection, then close after brief delay
    this.renderCalendar();

    setTimeout(() => {
      this.updateInputValue();
      this.close();

      if (this.options.onDateSelect) {
        this.options.onDateSelect({
          jalali: this.selectedDate,
          gregorian: today,
          formatted: this.formatJalaliDate(this.selectedDate),
        });
      }
    }, 200); // Brief delay to show selection
  }

  clearDate() {
    // Clear the selected date
    this.selectedDate = null;
    this.currentDate = new Date();

    // Update the input and UI
    this.updateInputValue();

    // Close the picker if it's open
    if (this.isOpen) {
      this.close();
    }

    // Call callback if provided
    if (this.options.onDateSelect) {
      this.options.onDateSelect({
        jalali: null,
        gregorian: null,
        formatted: "",
      });
    }

  }

  updateInputValue() {
    if (this.selectedDate) {
      // Update the hidden input with Gregorian date
      const gregorianDate = this.jalaliToGregorian(
        this.selectedDate.year,
        this.selectedDate.month,
        this.selectedDate.day,
      );

      const gregorianStr =
        gregorianDate.getFullYear() +
        "-" +
        String(gregorianDate.getMonth() + 1).padStart(2, "0") +
        "-" +
        String(gregorianDate.getDate()).padStart(2, "0");

      this.input.value = gregorianStr;

      // Update the trigger button text with Persian date
      const triggerText = this.triggerButton.querySelector("span");
      triggerText.textContent = this.formatJalaliDate(this.selectedDate);

      // Show clear button when date is selected
      this.clearButton.style.display = "flex";
    } else {
      this.input.value = "";
      const triggerText = this.triggerButton.querySelector("span");
      triggerText.textContent = "انتخاب تاریخ";

      // Hide clear button when no date is selected
      this.clearButton.style.display = "none";
    }

    // Trigger change event on the original input
    this.input.dispatchEvent(new Event("change", { bubbles: true }));
  }

  formatJalaliDate(jalaliDate) {
    if (!jalaliDate) return "";

    return `${jalaliDate.year}/${String(jalaliDate.month).padStart(
      2,
      "0",
    )}/${String(jalaliDate.day).padStart(2, "0")}`;
  }

  // Initialize from existing input value
  initializeFromInput() {
    if (this.input.value) {
      try {
        // Handle different date formats
        let dateValue = this.input.value.trim();

        // Skip if empty or invalid
        if (
          !dateValue ||
          dateValue === "NaN-NaN-NaN" ||
          dateValue.includes("undefined")
        ) {
          return;
        }

        // Check if the value is in Jalali format (YYYY/MM/DD with year > 1300)
        const jalaliPattern = /^(\d{4})\/(\d{1,2})\/(\d{1,2})$/;
        const jalaliMatch = dateValue.match(jalaliPattern);

        if (jalaliMatch) {
          const year = parseInt(jalaliMatch[1]);

          // If year is > 1300, it's likely a Jalali date (Persian calendar years are 1300+)
          if (year > 1300) {
            // Parse Jalali date
            const jalaliYear = year;
            const jalaliMonth = parseInt(jalaliMatch[2]);
            const jalaliDay = parseInt(jalaliMatch[3]);

            // Convert to Gregorian
            const gregorianDate = this.jalaliToGregorian(
              jalaliYear,
              jalaliMonth,
              jalaliDay,
            );

            this.selectedDate = {
              year: jalaliYear,
              month: jalaliMonth,
              day: jalaliDay,
            };
            this.currentDate = gregorianDate;

            // Update input with Gregorian format (for server)
            const gregorianStr =
              gregorianDate.getFullYear() +
              "-" +
              String(gregorianDate.getMonth() + 1).padStart(2, "0") +
              "-" +
              String(gregorianDate.getDate()).padStart(2, "0");

            this.input.value = gregorianStr;

            // Update trigger button with Jalali format
            const triggerText = this.triggerButton.querySelector("span");
            if (triggerText) {
              triggerText.textContent = dateValue;
            }

            return;
          }
        }

        // Otherwise, treat as Gregorian date (YYYY-MM-DD)
        const gregorianDate = new Date(dateValue + "T00:00:00");

        // Validate the date
        if (isNaN(gregorianDate.getTime())) {
          return;
        }

        this.selectedDate = this.gregorianToJalali(gregorianDate);
        this.currentDate = gregorianDate;
        this.updateInputValue();
      } catch (e) {}
    }
  }

  // Utility methods for Jalali calendar calculations
  gregorianToJalali(date) {
    try {
      if (typeof date === "string") {
        date = new Date(date + "T00:00:00");
      }

      // Validate input date
      if (!date || isNaN(date.getTime())) {
        return { year: 1400, month: 1, day: 1 }; // Default fallback
      }

      const gy = date.getFullYear();
      const gm = date.getMonth() + 1;
      const gd = date.getDate();

      const g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
      let gy2 = gm > 2 ? gy + 1 : gy;
      let days =
        355666 +
        365 * gy +
        Math.floor((gy2 + 3) / 4) -
        Math.floor((gy2 + 99) / 100) +
        Math.floor((gy2 + 399) / 400) +
        gd +
        g_d_m[gm - 1];

      let jy = -1595 + 33 * Math.floor(days / 12053);
      days %= 12053;
      jy += 4 * Math.floor(days / 1461);
      days %= 1461;

      if (days > 365) {
        jy += Math.floor((days - 1) / 365);
        days = (days - 1) % 365;
      }

      let jm, jd;
      if (days < 186) {
        jm = 1 + Math.floor(days / 31);
        jd = 1 + (days % 31);
      } else {
        jm = 7 + Math.floor((days - 186) / 30);
        jd = 1 + ((days - 186) % 30);
      }

      // Validate result
      if (
        isNaN(jy) ||
        isNaN(jm) ||
        isNaN(jd) ||
        jy < 1 ||
        jm < 1 ||
        jm > 12 ||
        jd < 1
      ) {
        return { year: 1400, month: 1, day: 1 }; // Default fallback
      }

      return { year: jy, month: jm, day: jd };
    } catch (error) {
      return { year: 1400, month: 1, day: 1 }; // Default fallback
    }
  }

  jalaliToGregorian(jy, jm, jd) {
    try {
      // Validate input parameters
      if (
        isNaN(jy) ||
        isNaN(jm) ||
        isNaN(jd) ||
        jy < 1 ||
        jm < 1 ||
        jm > 12 ||
        jd < 1
      ) {
        return new Date(); // Return current date as fallback
      }

      jy += 1595;
      let days =
        -355668 +
        365 * jy +
        Math.floor(jy / 33) * 8 +
        Math.floor(((jy % 33) + 3) / 4) +
        jd;

      if (jm < 7) {
        days += (jm - 1) * 31;
      } else {
        days += (jm - 7) * 30 + 186;
      }

      let gy = 400 * Math.floor(days / 146097);
      days %= 146097;

      if (days > 36524) {
        days -= 1;
        gy += 100 * Math.floor(days / 36524);
        days %= 36524;
        if (days >= 365) days += 1;
      }

      gy += 4 * Math.floor(days / 1461);
      days %= 1461;

      if (days > 365) {
        gy += Math.floor((days - 1) / 365);
        days = (days - 1) % 365;
      }

      let gd = days + 1;
      const isLeap = (gy % 4 === 0 && gy % 100 !== 0) || gy % 400 === 0;
      const sal_a = [
        0,
        31,
        isLeap ? 29 : 28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
      ];

      let gm = 0;
      while (gm < 13 && gd > sal_a[gm]) {
        gd -= sal_a[gm];
        gm += 1;
      }

      const result = new Date(gy, gm - 1, gd);

      // Validate result
      if (isNaN(result.getTime())) {
        return new Date(); // Return current date as fallback
      }

      return result;
    } catch (error) {
      return new Date(); // Return current date as fallback
    }
  }

  getJalaliMonthDays(year, month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return this.isLeapJalali(year) ? 30 : 29;
  }

  isLeapJalali(jy) {
    // Simplified leap year calculation for Jalali calendar
    const breaks = [
      -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097,
      2192, 2262, 2324, 2394, 2456, 3178,
    ];

    let jp = breaks[0];
    let j = 1;
    let jump = 0;

    for (let i = 1; i < breaks.length; i++) {
      const jm = breaks[i];
      jump = jm - jp;
      if (jy < jm) break;
      jp = jm;
      j++;
    }

    let n = jy - jp;

    if (n < jump) {
      if (jump - n < 6) n = n - jump + ((jump + 4) / 6) * 6;

      let leap = ((n + 1) % 33) % 4;
      if (jump == 33 && leap == 1) leap = 0;
      if (leap == 1) return true;
    }

    return false;
  }

  getFirstDayOfJalaliMonth(year, month) {
    const gregorianFirst = this.jalaliToGregorian(year, month, 1);
    // Convert to Persian weekday (Saturday = 0, Friday = 6)
    return (gregorianFirst.getDay() + 1) % 7;
  }

  isTodayJalali(year, month, day) {
    const today = new Date();
    const todayJalali = this.gregorianToJalali(today);

    return (
      todayJalali.year === year &&
      todayJalali.month === month &&
      todayJalali.day === day
    );
  }

  // Year selector functionality
  showYearSelector() {
    // Remove any existing selector first
    const existingSelector = this.dropdown.querySelector(
      ".year-month-selector",
    );
    if (existingSelector) {
      existingSelector.remove();
    }

    const currentJalali = this.gregorianToJalali(this.currentDate);
    const yearSelectorHtml = `
      <div class="year-month-selector" style="
        position: absolute !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
        background: white !important;
        border: 1px solid #ccc !important;
        padding: 8px !important;
        z-index: 999999 !important;
        display: flex !important;
        flex-direction: column !important;
        visibility: visible !important;
        opacity: 1 !important;
        pointer-events: auto !important;
      ">
        <div style="
          display: flex !important;
          justify-content: space-between !important;
          align-items: center !important;
          margin-bottom: 8px !important;
          padding-bottom: 8px !important;
          border-bottom: 1px solid #ddd !important;
        ">
          <h3 style="margin: 0 !important; color: #628db6 !important; font-size: 12px !important;">انتخاب سال</h3>
          <button type="button" class="close-selector" style="
            background: #f5f5f5 !important;
            border: 1px solid #ccc !important;
            padding: 4px 8px !important;
            cursor: pointer !important;
            font-size: 11px !important;
            color: #666 !important;
          ">بستن</button>
        </div>
        <div class="year-grid" style="
          display: grid !important;
          grid-template-columns: repeat(4, 1fr) !important;
          gap: 4px !important;
          max-height: 200px !important;
          overflow-y: auto !important;
          padding: 4px !important;
          border: 1px solid #ddd !important;
          background: white !important;
        ">
          ${this.generateYearOptions(currentJalali.year)}
        </div>
      </div>
    `;

    this.dropdown.style.position = "relative";
    this.dropdown.style.overflow = "hidden"; // Prevent content from spilling out
    this.dropdown.insertAdjacentHTML("beforeend", yearSelectorHtml);

    // Attach event listeners - Fixed to prevent closing picker
    const closeBtn = this.dropdown.querySelector(".close-selector");
    closeBtn.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.dropdown.querySelector(".year-month-selector").remove();
    });

    const yearButtons = this.dropdown.querySelectorAll(".year-option");
    yearButtons.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        const selectedYear = parseInt(btn.dataset.year);
        this.changeYear(selectedYear);
        this.dropdown.querySelector(".year-month-selector").remove();
      });
    });

    // Auto-scroll to current year in this year selector too
    setTimeout(() => {
      const currentYearButton = this.dropdown.querySelector(
        `[data-year="${currentJalali.year}"]`,
      );
      if (currentYearButton) {
        currentYearButton.scrollIntoView({
          behavior: "smooth",
          block: "center",
        });
      }
    }, 100);
  }

  // Month selector functionality
  showMonthSelector() {
    // Remove any existing selector first
    const existingSelector = this.dropdown.querySelector(
      ".year-month-selector",
    );
    if (existingSelector) {
      existingSelector.remove();
    }

    const monthSelectorHtml = `
      <div class="year-month-selector" style="
        position: absolute !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
        background: white !important;
        border: 1px solid #ccc !important;
        padding: 8px !important;
        z-index: 999999 !important;
        display: flex !important;
        flex-direction: column !important;
        visibility: visible !important;
        opacity: 1 !important;
        pointer-events: auto !important;
      ">
        <div style="
          display: flex !important;
          justify-content: space-between !important;
          align-items: center !important;
          margin-bottom: 8px !important;
          padding-bottom: 8px !important;
          border-bottom: 1px solid #ddd !important;
        ">
          <h3 style="margin: 0 !important; color: #628db6 !important; font-size: 12px !important;">انتخاب ماه</h3>
          <button type="button" class="close-selector" style="
            background: #f5f5f5 !important;
            border: 1px solid #ccc !important;
            padding: 4px 8px !important;
            cursor: pointer !important;
            font-size: 11px !important;
            color: #666 !important;
          ">بستن</button>
        </div>
        <div class="month-grid" style="
          display: grid !important;
          grid-template-columns: repeat(3, 1fr) !important;
          gap: 8px !important;
          padding: 4px !important;
        ">
          ${this.generateMonthOptions()}
        </div>
      </div>
    `;

    this.dropdown.style.position = "relative";
    this.dropdown.style.overflow = "hidden"; // Prevent content from spilling out
    this.dropdown.insertAdjacentHTML("beforeend", monthSelectorHtml);

    // Attach event listeners - Fixed to prevent closing picker
    const closeBtn = this.dropdown.querySelector(".close-selector");
    closeBtn.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.dropdown.querySelector(".year-month-selector").remove();
    });

    const monthButtons = this.dropdown.querySelectorAll(".month-option");
    monthButtons.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        const selectedMonth = parseInt(btn.dataset.month);
        this.changeMonth(selectedMonth);
        this.dropdown.querySelector(".year-month-selector").remove();
      });
    });
  }

  generateYearOptions(currentYear) {
    let options = "";
    // Expand year range significantly - from 1300 to 1450 (Persian years)
    // This covers approximately 1921 to 2071 in Gregorian calendar
    const startYear = 1300;
    const endYear = 1450;

    for (let year = startYear; year <= endYear; year++) {
      const isSelected = year === currentYear;
      const selectedClass = isSelected ? " selected" : "";

      options += `
        <button type="button" class="year-option${selectedClass}" data-year="${year}" style="
          padding: 8px 4px !important;
          border: 1px solid ${isSelected ? "#628db6" : "#ddd"} !important;
          background: ${isSelected ? "#628db6" : "white"} !important;
          color: ${isSelected ? "white" : "#333"} !important;
          cursor: pointer !important;
          font-size: 11px !important;
          font-weight: ${isSelected ? "bold" : "normal"} !important;
          border-radius: 3px !important;
          transition: all 0.2s ease !important;
          text-align: center !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
          min-height: 32px !important;
          box-shadow: ${
            isSelected ? "0 2px 4px rgba(98, 141, 182, 0.3)" : "none"
          } !important;
        ">
          ${year}
        </button>
      `;
    }
    return options;
  }

  generateMonthOptions() {
    const currentJalali = this.gregorianToJalali(this.currentDate);
    let options = "";

    PERSIAN_MONTHS.forEach((monthName, index) => {
      const monthNumber = index + 1;
      const isSelected = monthNumber === currentJalali.month;
      const selectedClass = isSelected ? " selected" : "";

      options += `
        <button type="button" class="month-option${selectedClass}" data-month="${monthNumber}" style="
          padding: 12px 8px !important;
          border: 1px solid ${isSelected ? "#628db6" : "#ddd"} !important;
          background: ${isSelected ? "#628db6" : "white"} !important;
          color: ${isSelected ? "white" : "#333"} !important;
          cursor: pointer !important;
          font-size: 11px !important;
          font-weight: ${isSelected ? "bold" : "normal"} !important;
          text-align: center !important;
          width: 100% !important;
          min-width: 70px !important;
          max-width: 85px !important;
          min-height: 40px !important;
          box-sizing: border-box !important;
          overflow: hidden !important;
          text-overflow: ellipsis !important;
          white-space: nowrap !important;
          border-radius: 3px !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
          transition: all 0.2s ease !important;
          box-shadow: ${
            isSelected ? "0 2px 4px rgba(98, 141, 182, 0.3)" : "none"
          } !important;
        ">
          ${monthName}
        </button>
      `;
    });
    return options;
  }

  changeYear(newYear) {
    const currentJalali = this.gregorianToJalali(this.currentDate);
    this.currentDate = this.jalaliToGregorian(newYear, currentJalali.month, 1);
    this.renderCalendar();
  }

  changeMonth(newMonth) {
    const currentJalali = this.gregorianToJalali(this.currentDate);
    this.currentDate = this.jalaliToGregorian(currentJalali.year, newMonth, 1);
    this.renderCalendar();
  }
}

// Auto-initialize Jalali date pickers
window.JalaliDatePicker = JalaliDatePicker;

// Static method to check if input already has a picker
JalaliDatePicker.hasPickerFor = function (inputElement) {
  if (!inputElement) return false;

  // Check if input has data attribute
  if (inputElement.getAttribute("data-jalali-picker") === "true") {
    return true;
  }

  // Check if input is hidden (being handled by Persian date input handler)
  if (inputElement.type === "hidden" || inputElement.style.display === "none") {
    // Check if there's a Persian date input handler managing this field
    const nextSibling = inputElement.nextElementSibling;
    if (nextSibling && nextSibling.classList.contains("persian-date-input")) {
      return true; // Skip this input, it's being handled by another system
    }
  }

  // Check if next sibling is a jalali container
  if (
    inputElement.nextElementSibling &&
    inputElement.nextElementSibling.classList.contains(
      "jalali-date-picker-container",
    )
  ) {
    return true;
  }

  return false;
};

// Auto-initialize Jalali date pickers for all date inputs
document.addEventListener("DOMContentLoaded", function () {
  // Function to initialize Jalali picker for a date input
  function initializeJalaliPicker(input) {
    // Skip if already has a Jalali picker
    if (JalaliDatePicker.hasPickerFor(input)) {
      return;
    }

    try {
      new JalaliDatePicker(input);
    } catch (error) {}
  }

  // Find all date inputs and initialize Jalali pickers
  function initializeAllDatePickers() {
    // Target all date inputs including:
    // 1. Standard date inputs: input[type="date"]
    // 2. Custom field date inputs: .date_cf
    // 3. Specific Redmine date fields by ID pattern
    const dateInputSelectors = [
      'input[type="date"]',
      "input.date_cf",
      'input[id*="custom_field_values"]',
      'input[id*="_date"]',
      'input[id*="due_date"]',
      'input[id*="start_date"]',
      'input[id*="effective_date"]',
      'input[id*="spent_on"]',
    ];

    dateInputSelectors.forEach((selector) => {
      const inputs = document.querySelectorAll(selector);
      inputs.forEach((input) => {
        // Only process actual date inputs
        if (input.type === "date" || input.classList.contains("date_cf")) {
          initializeJalaliPicker(input);
        }
      });
    });
  }

  // Initialize on page load
  initializeAllDatePickers();

  // Re-initialize when new content is dynamically added (for AJAX forms)
  const observer = new MutationObserver(function (mutations) {
    mutations.forEach(function (mutation) {
      if (mutation.addedNodes.length > 0) {
        // Check if any new date inputs were added
        mutation.addedNodes.forEach(function (node) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            // Check if the node itself is a date input
            if (
              (node.type === "date" || node.classList?.contains("date_cf")) &&
              !JalaliDatePicker.hasPickerFor(node)
            ) {
              initializeJalaliPicker(node);
            }

            // Check for date inputs within the added node
            const dateInputs = node.querySelectorAll
              ? node.querySelectorAll('input[type="date"], input.date_cf')
              : [];
            dateInputs.forEach((input) => {
              if (!JalaliDatePicker.hasPickerFor(input)) {
                initializeJalaliPicker(input);
              }
            });
          }
        });
      }
    });
  });

  // Start observing
  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });

});

// Static method to check if input already has a picker
JalaliDatePicker.hasPickerFor = function (inputElement) {
  if (!inputElement) return false;

  // Check if input has data attribute
  if (inputElement.getAttribute("data-jalali-picker") === "true") {
    return true;
  }

  // Check if input is hidden (being handled by Persian date input handler)
  if (inputElement.type === "hidden" || inputElement.style.display === "none") {
    // Check if there's a Persian date input handler managing this field
    const nextSibling = inputElement.nextElementSibling;
    if (nextSibling && nextSibling.classList.contains("persian-date-input")) {
      return true; // Skip this input, it's being handled by another system
    }
  }

  // Check if next sibling is a jalali container
  if (
    inputElement.nextElementSibling &&
    inputElement.nextElementSibling.classList.contains(
      "jalali-date-picker-container",
    )
  ) {
    return true;
  }

  return false;
};

// Make it globally available
window.JalaliDatePicker = JalaliDatePicker;
