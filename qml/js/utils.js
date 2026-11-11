/*
 * Formatting helpers, taken from Health's utils.js.
 *
 * Deliberately NOT a .pragma library: qsTr() only resolves in a JS resource that runs in
 * the importing component's scope. It also has no .import lines of its own: a script
 * without imports borrows those of the file importing it, which is how Format and
 * Formatter (Sailfish.Silica) are visible here.
 */

function pad2(n) {
    return (n < 10 ? "0" : "") + n;
}

// A Date as the local calendar day "YYYY-MM-DD" (never toISOString(), which is UTC).
function toLocalDateString(d) {
    if (!d) {
        return "";
    }
    return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate());
}

// "YYYY-MM-DD" as a local date; new Date("2026-08-19") would parse it as UTC.
function fromLocalDateString(s) {
    if (!s) {
        return null;
    }
    var parts = String(s).split("T")[0].split(" ")[0].split("-");
    if (parts.length < 3) {
        return null;
    }
    var d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
    return isNaN(d.getTime()) ? null : d;
}

function _asDate(v) {
    return v instanceof Date ? v : fromLocalDateString(v);
}

function formatDate(s) {
    var d = _asDate(s);
    return d === null ? "" : Qt.formatDate(d, Qt.DefaultLocaleShortDate);
}

// "17 Aug", or "17 Aug 2025" when it is not this year's.
function shortDate(d) {
    d = _asDate(d);
    if (d === null) {
        return "";
    }
    return Format.formatDate(d, d.getFullYear() === new Date().getFullYear() ? Formatter.DateMediumWithoutYear
                                                                             : Formatter.DateMedium);
}

// A date in full: "Saturday 15 May 2021".
function longDate(d) {
    d = _asDate(d);
    return d === null ? "" : Format.formatDate(d, Formatter.DateFull);
}

/*
 * Whole days from one calendar day to another, or null. Rounded: across a clock change
 * two local midnights are an hour short of a whole day.
 */
function daysBetween(from, to) {
    var a = _asDate(from);
    var b = _asDate(to);
    if (a === null || b === null) {
        return null;
    }
    a = new Date(a.getFullYear(), a.getMonth(), a.getDate());
    b = new Date(b.getFullYear(), b.getMonth(), b.getDate());
    return Math.round((b - a) / 86400000);
}

var _decimalPoint = Qt.locale().decimalPoint;

/*
 * A number with at most `decimals` decimals (trailing zeros dropped), in the locale's
 * decimal separator ("72,5" in French). No thousands separators.
 */
function formatValue(v, decimals) {
    if (v === null || v === undefined || v === "" || isNaN(v)) {
        return "";
    }
    var d = (decimals === undefined || decimals === null) ? 1 : decimals;
    var factor = Math.pow(10, d);
    return String(Math.round(Number(v) * factor) / factor).replace(".", _decimalPoint);
}

// A number with exactly `decimals` decimals ("72.0"), for values shown side by side.
function formatFixed(v, decimals) {
    if (v === null || v === undefined || v === "" || isNaN(v)) {
        return "";
    }
    return Number(v).toFixed(decimals).replace(".", _decimalPoint);
}

/*
 * A stored number put back into a text field for editing. The fields take "." or ","
 * and nothing else, so the locale's separator is only used when it is ",".
 */
function formatInput(v) {
    if (v === null || v === undefined || v === "" || isNaN(v)) {
        return "";
    }
    var s = String(Math.round(Number(v) * 100) / 100);
    return _decimalPoint === "," ? s.replace(".", ",") : s;
}

// "72.5 kg": a weight with its unit.
function kg(v) {
    //: A weight in kilograms, %1 is the number
    return qsTr("%1 kg").arg(formatValue(v, 1));
}

// "Today", "Yesterday", then the weekday and date (the year only when not this one).
function dayTitle(day) {
    var d = fromLocalDateString(day);
    if (d === null) {
        return "";
    }
    var today = new Date();
    var days = daysBetween(d, today);
    if (days === 0) {
        return qsTr("Today");
    }
    if (days === 1) {
        return qsTr("Yesterday");
    }
    return Format.formatDate(d, d.getFullYear() === today.getFullYear() ? Formatter.DateFullWithoutYear
                                                                         : Formatter.DateFull);
}

// When a weight was taken: "Measured today", "Measured 3 days ago", "Measured 17 Aug".
function measuredWhen(day) {
    var d = fromLocalDateString(day);
    if (d === null) {
        return "";
    }
    var days = daysBetween(d, new Date());
    if (days <= 0) {
        return qsTr("Measured today");
    }
    if (days === 1) {
        return qsTr("Measured yesterday");
    }
    if (days < 7) {
        return qsTr("Measured %n day(s) ago", "", days);
    }
    //: %1 is a date, e.g. "Measured 17 Aug"
    return qsTr("Measured %1").arg(shortDate(d));
}

// "−0.8 kg since 9 Oct", from the first to the last of chart points [{t, v}]; "" with fewer than two.
function changeSinceText(points) {
    if (!points || points.length < 2) {
        return "";
    }
    var delta = points[points.length - 1].v - points[0].v;
    //: Change of the weight over a period, e.g. "−0.8 kg since 9 Oct"
    return qsTr("%1 since %2").arg((delta < 0 ? "−" : delta > 0 ? "+" : "±") + kg(Math.abs(delta)))
                              .arg(shortDate(new Date(points[0].t)));
}

// "1.3 kg from target", "On target", or "" without a target.
function targetText(latest, target) {
    if (latest === null || latest === undefined || target === null || target === undefined) {
        return "";
    }
    var distance = Math.abs(latest - target);
    if (formatValue(distance, 1) === formatValue(0, 1)) {
        //: Under the latest weight when it matches the target weight
        return qsTr("On target");
    }
    //: How far the latest weight is from the target, e.g. "1.3 kg from target"
    return qsTr("%1 from target").arg(kg(distance));
}

// Age in whole years on a birthday ("YYYY-MM-DD"), or -1 when unknown.
function ageFrom(birthday) {
    var born = fromLocalDateString(birthday);
    if (born === null) {
        return -1;
    }
    var today = new Date();
    var age = today.getFullYear() - born.getFullYear();
    if (today.getMonth() < born.getMonth()
            || (today.getMonth() === born.getMonth() && today.getDate() < born.getDate())) {
        age--;
    }
    return age >= 0 ? age : -1;
}

function genderName(gender) {
    return gender === "M" ? qsTr("Male") : qsTr("Female");
}

// "Female · 36 years · 165 cm", the line under a profile's name.
function profileDetail(profile) {
    var parts = [genderName(profile.gender)];
    var age = ageFrom(profile.birthday);
    if (age >= 0) {
        //: A profile's age
        parts.push(qsTr("%n year(s)", "", age));
    }
    if (profile.height !== null) {
        //: A height in centimetres, %1 is the number
        parts.push(qsTr("%1 cm").arg(formatValue(profile.height, 1)));
    }
    return parts.join(" · ");
}

// The letters in a profile's round badge.
function initials(firstName, lastName) {
    return ((firstName ? firstName.charAt(0) : "") + (lastName ? lastName.charAt(0) : "")).toUpperCase();
}

// Band colours, as stable names, the way Health stores them.
function constraintColor(name) {
    switch (name) {
    case "green":  return "#2ecc71";
    case "orange": return "#e67e22";
    case "red":    return "#e74c3c";
    case "blue":   return "#3498db";
    default:       return "";
    }
}

// vim:et:ts=4:sw=4
