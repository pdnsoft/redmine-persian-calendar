/**
 * Persian Calendar Date Converter - JDF.SCR.IR Algorithm
 * Provides accurate bidirectional conversion between Gregorian and Persian dates
 * Author: Based on JDF.SCR.IR - Most accurate Persian calendar converter
 */

class PersianDateConverter {
  /**
   * Convert Gregorian date to Persian/Jalali date
   * @param {Date|string} gregorianDate - Gregorian date object or string
   * @returns {Object} {year, month, day} Persian date components
   */
  static gregorianToJalali(gregorianDate) {
    let date;
    if (typeof gregorianDate === "string") {
      date = new Date(gregorianDate);
    } else if (gregorianDate instanceof Date) {
      date = gregorianDate;
    } else {
      throw new Error("Invalid date format");
    }

    const gy = date.getFullYear();
    const gm = date.getMonth() + 1; // JavaScript months are 0-based
    const gd = date.getDate();

    return this.gregorianToJalaliJDF(gy, gm, gd);
  }

  /**
   * Convert Persian/Jalali date to Gregorian date
   * @param {number|Object} year - Persian year or {year, month, day} object
   * @param {number} month - Persian month (1-12)
   * @param {number} day - Persian day (1-31)
   * @returns {Date} Gregorian Date object
   */
  static jalaliToGregorian(year, month, day) {
    let jy, jm, jd;

    if (typeof year === "object") {
      jy = year.year;
      jm = year.month;
      jd = year.day;
    } else {
      jy = year;
      jm = month;
      jd = day;
    }

    const [gy, gm, gd] = this.jalaliToGregorianJDF(jy, jm, jd);
    return new Date(gy, gm - 1, gd); // JavaScript months are 0-based
  }

  /**
   * JDF.SCR.IR Gregorian to Jalali conversion algorithm
   * @param {number} gy - Gregorian year
   * @param {number} gm - Gregorian month
   * @param {number} gd - Gregorian day
   * @returns {Object} {year, month, day}
   */
  static gregorianToJalaliJDF(gy, gm, gd) {
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

    return { year: jy, month: jm, day: jd };
  }

  /**
   * JDF.SCR.IR Jalali to Gregorian conversion algorithm
   * @param {number} jy - Jalali year
   * @param {number} jm - Jalali month
   * @param {number} jd - Jalali day
   * @returns {Array} [gy, gm, gd]
   */
  static jalaliToGregorianJDF(jy, jm, jd) {
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

    // Calculate month
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

    return [gy, gm, gd];
  }

  /**
   * Format Persian date as string
   * @param {Object} persianDate - {year, month, day}
   * @param {string} format - Format pattern (default: 'YYYY/MM/DD')
   * @returns {string} Formatted Persian date string
   */
  static formatPersianDate(persianDate, format = "YYYY/MM/DD") {
    const { year, month, day } = persianDate;

    return format
      .replace("YYYY", year.toString())
      .replace("MM", month.toString().padStart(2, "0"))
      .replace("DD", day.toString().padStart(2, "0"))
      .replace("M", month.toString())
      .replace("D", day.toString());
  }

  /**
   * Parse Persian date string
   * @param {string} persianDateString - Persian date string (YYYY/MM/DD or YYYY-MM-DD)
   * @returns {Object} {year, month, day} or null if invalid
   */
  static parsePersianDate(persianDateString) {
    if (!persianDateString || typeof persianDateString !== "string") {
      return null;
    }

    const parts = persianDateString.split(/[\/\-]/);
    if (parts.length !== 3) {
      return null;
    }

    const year = parseInt(parts[0]);
    const month = parseInt(parts[1]);
    const day = parseInt(parts[2]);

    // Basic validation
    if (isNaN(year) || isNaN(month) || isNaN(day)) {
      return null;
    }

    if (
      year < 1300 ||
      year > 1500 ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31
    ) {
      return null;
    }

    return { year, month, day };
  }

  /**
   * Validate Persian date
   * @param {number} year - Persian year
   * @param {number} month - Persian month
   * @param {number} day - Persian day
   * @returns {boolean} True if valid
   */
  static isValidPersianDate(year, month, day) {
    if (year < 1300 || year > 1500) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;

    // Check days in month
    if (month <= 6 && day > 31) return false;
    if (month > 6 && month <= 11 && day > 30) return false;
    if (month === 12) {
      const isLeapYear = this.isPersianLeapYear(year);
      if (day > (isLeapYear ? 30 : 29)) return false;
    }

    return true;
  }

  /**
   * Check if Persian year is leap year
   * @param {number} year - Persian year
   * @returns {boolean} True if leap year
   */
  static isPersianLeapYear(year) {
    const cycle = year % 33;
    return [1, 5, 9, 13, 17, 22, 26, 30].includes(cycle);
  }

  /**
   * Get Persian month names
   * @returns {Array} Array of Persian month names
   */
  static getPersianMonthNames() {
    return [
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
  }

  /**
   * Get Persian day names
   * @returns {Array} Array of Persian day names
   */
  static getPersianDayNames() {
    return [
      "یکشنبه",
      "دوشنبه",
      "سه‌شنبه",
      "چهارشنبه",
      "پنج‌شنبه",
      "جمعه",
      "شنبه",
    ];
  }
}

// Make it available globally
window.PersianDateConverter = PersianDateConverter;
