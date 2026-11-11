.pragma library

/*
 * A Health backup made from Weight Tracker's data, to move to Health.
 *
 * Health (harbour-health) restores only its own full backups, and a restore replaces
 * everything in Health. The file built here is one such backup: every profile with its
 * weights, its height and its target weight. It is meant for a Health that has nothing
 * in it yet.
 *
 * What Health checks and does is in harbour-health/qml/js/DataManager.js:
 * inspectBackup() and restoreAll(). The restore deletes Metrics, Modules and
 * ProfileModules too and writes back those of the file, so the file carries Health's
 * built-in rows with their ids (DEFAULT_METRICS and DEFAULT_MODULES there, in that
 * order): without them the weights would point at no metric and the dashboard would
 * have no cards. Reference ranges (MetricConstraints) and the dashboard order
 * (ModuleOrder) are left out: Health puts its defaults back after a restore.
 */

var HEALTH_FORMAT = "harbour-health-backup";
var HEALTH_SCHEMA_VERSION = 1;

// Health's DEFAULT_METRICS: [name, unit, grouped, category]; ids are 1, 2, ...
var METRICS = [
    ["weight", "kg", 0, "Body"],
    ["height", "cm", 0, "Body"],
    ["calories", "kcal", 1, "Nutrition"],
    ["water", "L", 1, "Nutrition"],
    ["heartrate", "bpm", 0, "Blood"],
    ["systolic blood pressure", "mmHg", 0, "Blood"],
    ["diastolic blood pressure", "mmHg", 0, "Blood"],
    ["glucose", "mg/dL", 0, "Blood"],
    ["waist", "cm", 0, "Body"],
    ["calories burned", "kcal", 1, "Activity"]
];
var WEIGHT_METRIC_ID = 1;
var HEIGHT_METRIC_ID = 2;

// Health's DEFAULT_MODULES: [name, type, uses, category, icon]; all shown by default.
var MODULES = [
    ["Weight", "Metric", "weight", "Body", "scale.png"],
    ["Height", "Metric", "height", "Body", "height.png"],
    ["BMI", "Calc", "bmi", "Body", "gauge.png"],
    ["Calories", "Metric", "calories", "Nutrition", "fire.png"],
    ["Water", "Metric", "water", "Nutrition", "water.png"],
    ["Heartrate", "Metric", "heartrate", "Blood", "heart-pulse.png"],
    ["Blood Pressure", "Calc", "blood-pressure", "Blood", "blood-pressure.svg"],
    ["Glucose", "Metric", "glucose", "Blood", "diabetes.png"],
    ["Health Condition", "Summary", "MainHealthCondition", "Other", "medical-bag.png"],
    ["Vaccination", "Summary", "VaccinesList", "Other", "needle.png"],
    ["Meditation", "Summary", "MeditationMenu", "Other", "meditation.png"],
    ["Menstruation", "Summary", "Menstruation", "Other", "calendar-heart.png"],
    ["Waist", "Metric", "waist", "Body", "waist.svg"],
    ["WHtR", "Calc", "whtr", "Body", "whtr.svg"],
    ["Activity", "Metric", "calories burned", "Activity", "activity.svg"],
    ["Today", "Summary", "TodayPage", "Daily", "today.svg"]
];

function _pad2(n) {
    return (n < 10 ? "0" : "") + n;
}

function _timestamp(d) {
    return d.getFullYear() + "-" + _pad2(d.getMonth() + 1) + "-" + _pad2(d.getDate())
            + "T" + _pad2(d.getHours()) + ":" + _pad2(d.getMinutes()) + ":" + _pad2(d.getSeconds());
}

/*
 * Profiles that cannot go to Health as they are: Health needs a first and a last name
 * and a birthday. [{code, firstName, lastName}]
 */
function problems(profiles) {
    var list = [];
    for (var i = 0; i < profiles.length; i++) {
        var p = profiles[i];
        if (!p.birthdayValid || p.firstName === "" || p.lastName === "") {
            list.push(p);
        }
    }
    return list;
}

/*
 * The backup: `profiles` as Database.profiles() gives them, `weightsOf(code)` the
 * weights of one as Database.weights() gives them, `currentCode` the profile shown in
 * Weight Tracker (Health opens on it), `now` a Date.
 *
 * Weights have a day and no time. Each is put at midday, and several on one day a
 * minute apart in the order they were added. A profile's height becomes one height
 * reading just before its first weight, so Health can work out the BMI of every one.
 */
function build(profiles, weightsOf, currentCode, now) {
    var tables = {
        Profiles: [],
        Metrics: [],
        Modules: [],
        ProfileModules: [],
        HealthLogs: [],
        Goals: []
    };
    var i;
    for (i = 0; i < METRICS.length; i++) {
        tables.Metrics.push({ id: i + 1, name: METRICS[i][0], unit: METRICS[i][1],
                              grouped: METRICS[i][2], category: METRICS[i][3] });
    }
    for (i = 0; i < MODULES.length; i++) {
        tables.Modules.push({ id: i + 1, name: MODULES[i][0], type: MODULES[i][1], uses: MODULES[i][2],
                              bydefault: 1, category: MODULES[i][3], icon: MODULES[i][4] });
    }

    var stamp = _timestamp(now);
    var logId = 0;
    for (var p = 0; p < profiles.length; p++) {
        var profile = profiles[p];
        var row = {
            id: profile.code,
            firstName: profile.firstName,
            lastName: profile.lastName,
            gender: profile.gender === "M" ? "male" : "female",
            birthDate: profile.birthday,
            created: stamp
        };
        if (profile.code === currentCode) {
            row.lastUsed = stamp;
        }
        tables.Profiles.push(row);
        for (i = 0; i < MODULES.length; i++) {
            tables.ProfileModules.push({ profileId: profile.code, moduleId: i + 1 });
        }

        // Oldest first, so the minutes follow the order the weights were added.
        var weights = weightsOf(profile.code).slice().reverse();
        var firstDay = weights.length > 0 ? weights[0].date : stamp.substring(0, 10);
        if (profile.height !== null) {
            tables.HealthLogs.push({ id: ++logId, profileId: profile.code, metricId: HEIGHT_METRIC_ID,
                                     timestamp: firstDay + "T11:59:00", value: profile.height, note: "" });
        }
        var previous = "";
        var sameDay = 0;
        for (var w = 0; w < weights.length; w++) {
            sameDay = weights[w].date === previous ? sameDay + 1 : 0;
            previous = weights[w].date;
            tables.HealthLogs.push({ id: ++logId, profileId: profile.code, metricId: WEIGHT_METRIC_ID,
                                     timestamp: weights[w].date + "T12:" + _pad2(Math.min(sameDay, 59)) + ":00",
                                     value: weights[w].value, note: "" });
        }
        if (profile.target !== null) {
            tables.Goals.push({ profileId: profile.code, metricName: "weight", value: profile.target });
        }
    }

    return {
        format: HEALTH_FORMAT,
        schemaVersion: HEALTH_SCHEMA_VERSION,
        exportedAt: stamp,
        tables: tables
    };
}

// vim:et:ts=4:sw=4
