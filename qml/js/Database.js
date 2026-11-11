.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

/*
 * Every read and write of the app's data.
 *
 * Version 1.3 opened the database about thirty times, with SQL spread over the pages.
 * The tables and their columns are kept as they were, so existing data stays where it
 * is; what changed is listed with SCHEMA_VERSION below.
 *
 *   USERS    (USER_CODE, LASTNAME, FIRSTNAME, GENDER 'F'/'M', BIRTHDAY 'yyyy-MM-dd',
 *             HEIGHT cm, TARGET kg or NULL)
 *   METRICS  (USER_CODE, METRIC_CODE, METRIC_DATE 'yyyy-MM-dd', CATEGORIE 'WEIGHT', VAL kg)
 *   SETTINGS (USER_CODE): the profile shown, one row.
 *
 * METRIC_CODE is unique across profiles (version 1.3 numbered it that way), and the
 * order weights were added on the same day.
 */

var DB_NAME = "WeightTracker";
// LocalStorage's own version label, kept in its .ini file next to the database. It
// must never change: openDatabaseSync() refuses a database whose label differs.
var DB_VERSION = "1.0";
var DB_DESCRIPTION = "Weight Tracker";
var DB_SIZE = 1000000;

/*
 * 1: version 1.x, which had no SchemaInfo table.
 * 2: version 2.0. Birthdays in "yyyy-MM-dd" (1.x stored the phone's short date format,
 *    "15/05/2021" in French), heights and weights as numbers (one typed with a comma
 *    was kept as text), a TARGET column, and an index for the history queries.
 */
var SCHEMA_VERSION = 2;

var BACKUP_FORMAT = "harbour-weight-tracker-backup";
var TABLES = ["USERS", "METRICS", "SETTINGS"];
var COLUMNS = {
    USERS: ["USER_CODE", "LASTNAME", "FIRSTNAME", "GENDER", "BIRTHDAY", "HEIGHT", "TARGET"],
    METRICS: ["USER_CODE", "METRIC_CODE", "METRIC_DATE", "CATEGORIE", "VAL"],
    SETTINGS: ["USER_CODE"]
};

// What a weight and a height can be. Health uses the same weight limits.
var WEIGHT_MIN = 0.5;
var WEIGHT_MAX = 500;
var HEIGHT_MIN = 50;
var HEIGHT_MAX = 250;

var _db = null;

function _failure(reason, message) {
    var error = new Error(message);
    error.reason = reason;
    return error;
}

function _open() {
    if (_db === null) {
        _db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    }
    return _db;
}

/*
 * Several statements that take effect together or not at all (Health's _atomic).
 *
 * LocalStorage's transaction() does not give that on Qt 5.6: when its callback throws,
 * what ran before the error is still committed. The work runs inside a savepoint that
 * is rolled back before transaction() commits, and the error is passed on after.
 */
function _write(work) {
    var failed = false;
    var failure;
    var result;
    _open().transaction(function (tx) {
        tx.executeSql('SAVEPOINT wt_atomic');
        try {
            result = work(tx);
        } catch (error) {
            failed = true;
            failure = error;
            tx.executeSql('ROLLBACK TO wt_atomic');
        }
        tx.executeSql('RELEASE wt_atomic');
    });
    if (failed) {
        throw failure;
    }
    return result;
}

function _read(work) {
    var result;
    _open().readTransaction(function (tx) {
        result = work(tx);
    });
    return result;
}

function _pad2(n) {
    return (n < 10 ? "0" : "") + n;
}

// A Date as the local calendar day "yyyy-MM-dd" (never toISOString(), which is UTC).
function dateString(d) {
    return d.getFullYear() + "-" + _pad2(d.getMonth() + 1) + "-" + _pad2(d.getDate());
}

// "yyyy-MM-dd" as a local Date at midnight, or null.
function parseDate(s) {
    var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s ? String(s) : "");
    if (!match) {
        return null;
    }
    var d = new Date(parseInt(match[1], 10), parseInt(match[2], 10) - 1, parseInt(match[3], 10));
    return isNaN(d.getTime()) ? null : d;
}

function isDateString(s) {
    return parseDate(s) !== null;
}

function _timestamp(d) {
    return dateString(d) + "T" + _pad2(d.getHours()) + ":" + _pad2(d.getMinutes()) + ":" + _pad2(d.getSeconds());
}

// A number typed or stored with "." or ",", or NaN. "70|5" and "12abc" are not numbers.
function parseNumber(value) {
    if (typeof value === "number") {
        return value;
    }
    var text = value === null || value === undefined ? "" : String(value).trim();
    if (!/^\d+([.,]\d+)?$/.test(text)) {
        return NaN;
    }
    return parseFloat(text.replace(",", "."));
}

/*
 * A birthday stored by version 1.x, as "yyyy-MM-dd", or "" when it cannot be read.
 *
 * 1.x meant to store "yyyy-MM-dd" but stored the phone's short date format instead:
 * "15/05/2021" in French or British English, "5/15/21" in American English, "15.05.21"
 * in German. The day, month and year are read in the order of the phone's own short
 * format, which is the one that wrote them. A two-digit year is taken in the century
 * that makes the birthday at most 100 years ago and not in the future.
 */
function normalizeBirthday(stored, locale) {
    var text = stored === null || stored === undefined ? "" : String(stored).trim();
    if (isDateString(text)) {
        return text;
    }
    var today = new Date();

    function make(year, month, day) {
        if (year < 100) {
            year += 2000;
            if (year > today.getFullYear()) {
                year -= 100;
            }
        }
        var d = new Date(year, month - 1, day);
        if (isNaN(d.getTime()) || d.getMonth() !== month - 1 || d.getDate() !== day || d > today) {
            return "";
        }
        return dateString(d);
    }

    var parts = /^(\d{1,4})\D+(\d{1,2})\D+(\d{1,4})\D*$/.exec(text);
    if (parts) {
        var numbers = [parseInt(parts[1], 10), parseInt(parts[2], 10), parseInt(parts[3], 10)];
        if (parts[1].length === 4) {
            return make(numbers[0], numbers[1], numbers[2]);
        }
        // The order of day (d), month (M) and year (y) in the phone's short format.
        var format = locale ? String(locale.dateFormat(1)) : "dd/MM/yyyy";
        var order = format.replace(/[^dMy]/g, "").replace(/(.)\1+/g, "$1");
        var day = numbers[order.indexOf("d")];
        var month = numbers[order.indexOf("M")];
        var year = numbers[order.indexOf("y")];
        if (order.length === 3 && day !== undefined && month !== undefined && year !== undefined) {
            var result = make(year, month, day);
            if (result !== "") {
                return result;
            }
        }
        // Day first is what most of the world writes.
        return make(numbers[2], numbers[1], numbers[0]);
    }

    // A long format ("samedi 15 mai 2021"), as some Qt versions wrote it.
    if (locale) {
        for (var formatType = 0; formatType <= 2; formatType++) {
            try {
                var parsed = Date.fromLocaleDateString(locale, text, formatType);
                if (parsed && !isNaN(parsed.getTime())) {
                    return make(parsed.getFullYear(), parsed.getMonth() + 1, parsed.getDate());
                }
            } catch (error) {
                // Try the next format.
            }
        }
    }
    return "";
}

// --- schema --------------------------------------------------------------------------

function _tableExists(tx, name) {
    return tx.executeSql("SELECT count(*) AS found FROM sqlite_master WHERE type='table' AND name=?",
                         [name]).rows.item(0).found > 0;
}

function _columns(tx, table) {
    var columns = {};
    var rs = tx.executeSql('PRAGMA table_info(' + table + ')');
    for (var i = 0; i < rs.rows.length; i++) {
        columns[rs.rows.item(i).name] = true;
    }
    return columns;
}

/*
 * The schema the database has: 0 for a new one, 1 for version 1.x, 2 for this one.
 * Creates nothing, so the window can save a copy before an upgrade.
 */
function storedSchemaVersion() {
    return _read(function (tx) {
        if (_tableExists(tx, "SchemaInfo")) {
            var rs = tx.executeSql('SELECT max(version) AS version FROM SchemaInfo');
            return rs.rows.item(0).version || 0;
        }
        return _tableExists(tx, "USERS") ? 1 : 0;
    });
}

function _createTables(tx) {
    tx.executeSql('CREATE TABLE IF NOT EXISTS SETTINGS (USER_CODE INTEGER NOT NULL, PRIMARY KEY(USER_CODE))');
    tx.executeSql('CREATE TABLE IF NOT EXISTS USERS (' +
                  'USER_CODE INTEGER NOT NULL, ' +
                  'LASTNAME VARCHAR(30) NOT NULL, ' +
                  'FIRSTNAME VARCHAR(30) NOT NULL, ' +
                  'GENDER CHAR(1) NOT NULL, ' +
                  'BIRTHDAY DATE NOT NULL, ' +
                  'HEIGHT INTEGER NOT NULL, ' +
                  'TARGET REAL, ' +
                  'PRIMARY KEY(USER_CODE))');
    tx.executeSql('CREATE TABLE IF NOT EXISTS METRICS (' +
                  'USER_CODE INTEGER NOT NULL, ' +
                  'METRIC_CODE INTEGER NOT NULL, ' +
                  'METRIC_DATE DATE NOT NULL, ' +
                  'CATEGORIE VARCHAR(20) NOT NULL, ' +
                  'VAL DECIMAL(3,2) NOT NULL, ' +
                  'PRIMARY KEY(USER_CODE, METRIC_CODE), ' +
                  'FOREIGN KEY(USER_CODE) REFERENCES USERS(USER_CODE))');
    tx.executeSql('CREATE TABLE IF NOT EXISTS SchemaInfo (version INTEGER PRIMARY KEY)');
}

// 1.x to 2: see SCHEMA_VERSION. Rows it cannot repair are left as they were.
function _upgradeFrom1(tx, locale) {
    if (!_columns(tx, "USERS").TARGET) {
        tx.executeSql('ALTER TABLE USERS ADD COLUMN TARGET REAL');
    }
    var rs = tx.executeSql('SELECT USER_CODE, BIRTHDAY, HEIGHT FROM USERS');
    for (var i = 0; i < rs.rows.length; i++) {
        var user = rs.rows.item(i);
        var birthday = normalizeBirthday(user.BIRTHDAY, locale);
        if (birthday !== "" && birthday !== user.BIRTHDAY) {
            tx.executeSql('UPDATE USERS SET BIRTHDAY=? WHERE USER_CODE=?', [birthday, user.USER_CODE]);
        }
        var height = parseNumber(user.HEIGHT);
        if (typeof user.HEIGHT === "string" && !isNaN(height)) {
            tx.executeSql('UPDATE USERS SET HEIGHT=? WHERE USER_CODE=?', [height, user.USER_CODE]);
        }
    }
    rs = tx.executeSql("SELECT USER_CODE, METRIC_CODE, VAL FROM METRICS WHERE typeof(VAL) = 'text'");
    for (var j = 0; j < rs.rows.length; j++) {
        var row = rs.rows.item(j);
        var value = parseNumber(row.VAL);
        if (!isNaN(value)) {
            tx.executeSql('UPDATE METRICS SET VAL=? WHERE USER_CODE=? AND METRIC_CODE=?',
                          [value, row.USER_CODE, row.METRIC_CODE]);
        }
    }
}

/*
 * Creates or upgrades the schema. `locale` (Qt.locale()) reads the birthdays 1.x
 * stored in the phone's date format. Throws "schema-newer" for a database written by
 * a later version.
 */
function init(locale) {
    var from = storedSchemaVersion();
    if (from > SCHEMA_VERSION) {
        throw _failure("schema-newer", "The database was written by a newer version of Weight Tracker");
    }
    _write(function (tx) {
        _createTables(tx);
        if (from === 1) {
            _upgradeFrom1(tx, locale);
        }
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_metrics_user_date ON METRICS(USER_CODE, METRIC_DATE)');
        if (from < SCHEMA_VERSION) {
            tx.executeSql('DELETE FROM SchemaInfo');
            tx.executeSql('INSERT INTO SchemaInfo (version) VALUES (?)', [SCHEMA_VERSION]);
        }
    });
    return from;
}

// --- profiles ------------------------------------------------------------------------

function _profileFrom(row) {
    var height = parseNumber(row.HEIGHT);
    var target = row.TARGET === null || row.TARGET === undefined ? NaN : parseNumber(row.TARGET);
    return {
        code: row.USER_CODE,
        firstName: row.FIRSTNAME ? String(row.FIRSTNAME) : "",
        lastName: row.LASTNAME ? String(row.LASTNAME) : "",
        gender: row.GENDER === "M" ? "M" : "F",
        birthday: row.BIRTHDAY ? String(row.BIRTHDAY) : "",
        birthdayValid: isDateString(row.BIRTHDAY),
        height: isNaN(height) ? null : height,
        target: isNaN(target) ? null : target
    };
}

function profiles() {
    return _read(function (tx) {
        var list = [];
        var rs = tx.executeSql('SELECT * FROM USERS ORDER BY FIRSTNAME COLLATE NOCASE, LASTNAME COLLATE NOCASE, USER_CODE');
        for (var i = 0; i < rs.rows.length; i++) {
            list.push(_profileFrom(rs.rows.item(i)));
        }
        return list;
    });
}

function profile(code) {
    return _read(function (tx) {
        var rs = tx.executeSql('SELECT * FROM USERS WHERE USER_CODE=?', [code]);
        return rs.rows.length > 0 ? _profileFrom(rs.rows.item(0)) : null;
    });
}

// The profile shown: the one in SETTINGS, else the first one; -1 without any.
function currentProfile() {
    return _read(function (tx) {
        var rs = tx.executeSql('SELECT s.USER_CODE AS code FROM SETTINGS s JOIN USERS u ON u.USER_CODE = s.USER_CODE');
        if (rs.rows.length > 0) {
            return rs.rows.item(0).code;
        }
        rs = tx.executeSql('SELECT USER_CODE AS code FROM USERS ORDER BY USER_CODE LIMIT 1');
        return rs.rows.length > 0 ? rs.rows.item(0).code : -1;
    });
}

function _setCurrent(tx, code) {
    tx.executeSql('DELETE FROM SETTINGS');
    if (code >= 0) {
        tx.executeSql('INSERT INTO SETTINGS (USER_CODE) VALUES (?)', [code]);
    }
}

function setCurrentProfile(code) {
    _write(function (tx) {
        _setCurrent(tx, code);
    });
}

function _checkProfile(p) {
    if (!p.firstName || !p.lastName) {
        throw _failure("invalid", "A profile needs a first and a last name");
    }
    if (!isDateString(p.birthday)) {
        throw _failure("invalid", "Invalid birthday");
    }
    if (!(p.height >= HEIGHT_MIN && p.height <= HEIGHT_MAX)) {
        throw _failure("invalid", "Invalid height");
    }
}

// Adds a profile {firstName, lastName, gender, birthday, height} and shows it; its code.
function addProfile(p) {
    _checkProfile(p);
    return _write(function (tx) {
        var code = tx.executeSql('SELECT coalesce(max(USER_CODE), 0) + 1 AS code FROM USERS').rows.item(0).code;
        tx.executeSql('INSERT INTO USERS (USER_CODE, LASTNAME, FIRSTNAME, GENDER, BIRTHDAY, HEIGHT) VALUES (?,?,?,?,?,?)',
                      [code, p.lastName, p.firstName, p.gender === "M" ? "M" : "F", p.birthday, p.height]);
        _setCurrent(tx, code);
        return code;
    });
}

function updateProfile(code, p) {
    _checkProfile(p);
    _write(function (tx) {
        tx.executeSql('UPDATE USERS SET LASTNAME=?, FIRSTNAME=?, GENDER=?, BIRTHDAY=?, HEIGHT=? WHERE USER_CODE=?',
                      [p.lastName, p.firstName, p.gender === "M" ? "M" : "F", p.birthday, p.height, code]);
    });
}

// Deletes a profile and its weights; another profile is shown if it was this one.
function deleteProfile(code) {
    _write(function (tx) {
        tx.executeSql('DELETE FROM METRICS WHERE USER_CODE=?', [code]);
        tx.executeSql('DELETE FROM USERS WHERE USER_CODE=?', [code]);
        var rs = tx.executeSql('SELECT count(*) AS found FROM SETTINGS s JOIN USERS u ON u.USER_CODE = s.USER_CODE');
        if (rs.rows.item(0).found === 0) {
            rs = tx.executeSql('SELECT USER_CODE AS code FROM USERS ORDER BY USER_CODE LIMIT 1');
            _setCurrent(tx, rs.rows.length > 0 ? rs.rows.item(0).code : -1);
        }
    });
}

// The weight to reach in kg, or null to have none.
function setTarget(code, kg) {
    if (kg !== null && !(kg >= WEIGHT_MIN && kg <= WEIGHT_MAX)) {
        throw _failure("invalid", "Invalid target");
    }
    _write(function (tx) {
        tx.executeSql('UPDATE USERS SET TARGET=? WHERE USER_CODE=?', [kg, code]);
    });
}

// --- weights -------------------------------------------------------------------------

// Rows whose value is a number: one 1.x kept as unreadable text is left out.
var _VALID = "CATEGORIE = 'WEIGHT' AND typeof(VAL) IN ('real', 'integer')";

function _checkWeight(dateText, kg) {
    if (!isDateString(dateText)) {
        throw _failure("invalid", "Invalid date");
    }
    if (!(kg >= WEIGHT_MIN && kg <= WEIGHT_MAX)) {
        throw _failure("invalid", "Invalid weight");
    }
}

function addWeight(userCode, dateText, kg) {
    _checkWeight(dateText, kg);
    return _write(function (tx) {
        var code = tx.executeSql('SELECT coalesce(max(METRIC_CODE), 0) + 1 AS code FROM METRICS').rows.item(0).code;
        tx.executeSql("INSERT INTO METRICS (USER_CODE, METRIC_CODE, METRIC_DATE, CATEGORIE, VAL) VALUES (?,?,?,'WEIGHT',?)",
                      [userCode, code, dateText, kg]);
        return code;
    });
}

function updateWeight(userCode, metricCode, dateText, kg) {
    _checkWeight(dateText, kg);
    _write(function (tx) {
        tx.executeSql('UPDATE METRICS SET METRIC_DATE=?, VAL=? WHERE USER_CODE=? AND METRIC_CODE=?',
                      [dateText, kg, userCode, metricCode]);
    });
}

function deleteWeight(userCode, metricCode) {
    _write(function (tx) {
        tx.executeSql('DELETE FROM METRICS WHERE USER_CODE=? AND METRIC_CODE=?', [userCode, metricCode]);
    });
}

function clearWeights(userCode) {
    _write(function (tx) {
        tx.executeSql('DELETE FROM METRICS WHERE USER_CODE=?', [userCode]);
    });
}

function weight(userCode, metricCode) {
    return _read(function (tx) {
        var rs = tx.executeSql('SELECT METRIC_CODE, METRIC_DATE, VAL FROM METRICS WHERE USER_CODE=? AND METRIC_CODE=? AND ' + _VALID,
                               [userCode, metricCode]);
        return rs.rows.length > 0 ? { code: rs.rows.item(0).METRIC_CODE, date: rs.rows.item(0).METRIC_DATE,
                                      value: rs.rows.item(0).VAL } : null;
    });
}

// Every weight of a profile, newest first: [{code, date, value}].
function weights(userCode) {
    return _read(function (tx) {
        var list = [];
        var rs = tx.executeSql('SELECT METRIC_CODE, METRIC_DATE, VAL FROM METRICS WHERE USER_CODE=? AND ' + _VALID +
                               ' ORDER BY METRIC_DATE DESC, METRIC_CODE DESC', [userCode]);
        for (var i = 0; i < rs.rows.length; i++) {
            var row = rs.rows.item(i);
            list.push({ code: row.METRIC_CODE, date: row.METRIC_DATE, value: row.VAL });
        }
        return list;
    });
}

/*
 * The latest weight, by its date: {code, date, value} or null. Version 1.3 took the
 * last one added, so a weight added later for an earlier day became "the latest".
 */
function latestWeight(userCode) {
    return _read(function (tx) {
        var rs = tx.executeSql('SELECT METRIC_CODE, METRIC_DATE, VAL FROM METRICS WHERE USER_CODE=? AND ' + _VALID +
                               ' ORDER BY METRIC_DATE DESC, METRIC_CODE DESC LIMIT 1', [userCode]);
        return rs.rows.length > 0 ? { code: rs.rows.item(0).METRIC_CODE, date: rs.rows.item(0).METRIC_DATE,
                                      value: rs.rows.item(0).VAL } : null;
    });
}

function _since(days) {
    if (!days || days <= 0) {
        return "";
    }
    var d = new Date();
    d.setDate(d.getDate() - days + 1);
    return dateString(d);
}

/*
 * Chart points [{t, v}] from `days` days ago (0: all), oldest first. A day's weights
 * are drawn at midday, a minute apart in the order they were added.
 */
function series(userCode, days) {
    var since = _since(days);
    return _read(function (tx) {
        var points = [];
        var rs = tx.executeSql('SELECT METRIC_DATE, VAL FROM METRICS WHERE USER_CODE=? AND METRIC_DATE >= ? AND ' + _VALID +
                               ' ORDER BY METRIC_DATE, METRIC_CODE', [userCode, since]);
        var previous = "";
        var sameDay = 0;
        for (var i = 0; i < rs.rows.length; i++) {
            var row = rs.rows.item(i);
            var day = parseDate(row.METRIC_DATE);
            if (day === null) {
                continue;
            }
            sameDay = row.METRIC_DATE === previous ? sameDay + 1 : 0;
            previous = row.METRIC_DATE;
            day.setHours(12, sameDay, 0, 0);
            points.push({ t: day.getTime(), v: row.VAL });
        }
        return points;
    });
}

// {count, min, avg, max} of the weights from `days` days ago (0: all).
function stats(userCode, days) {
    var since = _since(days);
    return _read(function (tx) {
        var row = tx.executeSql('SELECT count(*) AS count, min(VAL) AS min, avg(VAL) AS avg, max(VAL) AS max ' +
                                'FROM METRICS WHERE USER_CODE=? AND METRIC_DATE >= ? AND ' + _VALID,
                                [userCode, since]).rows.item(0);
        return { count: row.count, min: row.min, avg: row.avg, max: row.max };
    });
}

// --- backup and restore --------------------------------------------------------------

// Every row of the three tables, as a backup file holds them.
function exportBackup() {
    return _read(function (tx) {
        var dump = {
            format: BACKUP_FORMAT,
            schemaVersion: SCHEMA_VERSION,
            exportedAt: _timestamp(new Date()),
            tables: {}
        };
        for (var i = 0; i < TABLES.length; i++) {
            var table = TABLES[i];
            var rows = [];
            if (_tableExists(tx, table)) {
                var rs = tx.executeSql('SELECT * FROM ' + table);
                for (var j = 0; j < rs.rows.length; j++) {
                    var item = rs.rows.item(j);
                    var plain = {};
                    for (var key in item) {
                        plain[key] = item[key];
                    }
                    rows.push(plain);
                }
            }
            dump.tables[table] = rows;
        }
        return dump;
    });
}

function _isArray(value) {
    return Object.prototype.toString.call(value) === "[object Array]";
}

/*
 * Checks a backup and says what is in it: {exportedAt, profiles: [names], entries}.
 * Touches nothing. Throws with a reason: "not-a-backup", "newer-backup", "no-profiles".
 */
function inspectBackup(dump) {
    var invalid = _failure("not-a-backup", "Not a Weight Tracker backup file");
    if (!dump || typeof dump !== "object" || dump.format !== BACKUP_FORMAT
            || !dump.tables || typeof dump.tables !== "object" || _isArray(dump.tables)) {
        throw invalid;
    }
    if (typeof dump.schemaVersion !== "number" || isNaN(dump.schemaVersion)) {
        throw invalid;
    }
    if (dump.schemaVersion > SCHEMA_VERSION) {
        throw _failure("newer-backup", "This backup was made by a newer version of Weight Tracker");
    }
    for (var i = 0; i < TABLES.length; i++) {
        var rows = dump.tables[TABLES[i]];
        if (rows === undefined || rows === null) {
            continue;
        }
        if (!_isArray(rows)) {
            throw invalid;
        }
        for (var j = 0; j < rows.length; j++) {
            if (!rows[j] || typeof rows[j] !== "object" || _isArray(rows[j])) {
                throw invalid;
            }
        }
    }
    var users = dump.tables.USERS || [];
    if (users.length === 0) {
        throw _failure("no-profiles", "This backup contains no profiles");
    }
    var names = [];
    for (var u = 0; u < users.length; u++) {
        names.push(((users[u].FIRSTNAME || "") + " " + (users[u].LASTNAME || "")).trim());
    }
    return {
        exportedAt: dump.exportedAt ? String(dump.exportedAt) : "",
        profiles: names,
        entries: (dump.tables.METRICS || []).length
    };
}

/*
 * Replaces all data with a backup's, in one transaction: a row the database refuses
 * leaves the data as it was. Only the known columns are written.
 */
function restoreBackup(dump) {
    inspectBackup(dump);
    _write(function (tx) {
        _createTables(tx);
        if (!_columns(tx, "USERS").TARGET) {
            tx.executeSql('ALTER TABLE USERS ADD COLUMN TARGET REAL');
        }
        for (var i = TABLES.length - 1; i >= 0; i--) {
            tx.executeSql('DELETE FROM ' + TABLES[i]);
        }
        for (i = 0; i < TABLES.length; i++) {
            var table = TABLES[i];
            var rows = dump.tables[table] || [];
            var known = COLUMNS[table];
            for (var j = 0; j < rows.length; j++) {
                var columns = [];
                var values = [];
                for (var c = 0; c < known.length; c++) {
                    if (rows[j][known[c]] !== undefined) {
                        columns.push(known[c]);
                        values.push(rows[j][known[c]]);
                    }
                }
                if (columns.length > 0) {
                    tx.executeSql('INSERT OR REPLACE INTO ' + table + ' (' + columns.join(",") + ') VALUES (' +
                                  columns.map(function () { return "?"; }).join(",") + ')', values);
                }
            }
        }
        if (tx.executeSql('SELECT count(*) AS count FROM USERS').rows.item(0).count === 0) {
            throw _failure("no-profiles", "This backup contains no profiles");
        }
    });
}

/*
 * Every weight as a CSV file for spreadsheets: profile, date, weight in kg. Every cell
 * quoted; a byte order mark so spreadsheets read it as UTF-8 ("Zoé", not "ZoÃ©").
 */
function exportCsv() {
    function quote(v) {
        return '"' + String(v === null || v === undefined ? "" : v).replace(/"/g, '""') + '"';
    }
    return _read(function (tx) {
        var lines = ['"profile","date","weight_kg"'];
        var rs = tx.executeSql("SELECT u.FIRSTNAME || ' ' || u.LASTNAME AS profile, m.METRIC_DATE AS date, m.VAL AS value " +
                               'FROM METRICS m JOIN USERS u ON u.USER_CODE = m.USER_CODE WHERE ' +
                               "m.CATEGORIE = 'WEIGHT' AND typeof(m.VAL) IN ('real', 'integer') " +
                               'ORDER BY u.USER_CODE, m.METRIC_DATE, m.METRIC_CODE');
        for (var i = 0; i < rs.rows.length; i++) {
            var row = rs.rows.item(i);
            lines.push([quote(row.profile), quote(row.date), quote(row.value)].join(","));
        }
        return "﻿" + lines.join("\n") + "\n";
    });
}

// vim:et:ts=4:sw=4
