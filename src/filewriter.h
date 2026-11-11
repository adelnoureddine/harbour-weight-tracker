/*
 * Weight Tracker for SailfishOS
 * Copyright (C) 2021-2026 Adel Noureddine
 * Licensed under the GNU GPL 3 license only (GPL-3.0-only).
 */

#ifndef FILEWRITER_H
#define FILEWRITER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

/*
 * Minimal file access for backups and exports, taken from Health.
 *
 * QML has no API for writing files, so this is the smallest possible bridge: plain
 * text in, plain text out. Writing and deleting are confined to three places, whatever
 * path QML passes: the WeightTracker folder in Documents (backups and CSV files the
 * user can copy away), the Health folder in Documents (the backup that moves the data
 * to Health), and the app's private backups folder (copies taken before an upgrade or
 * a restore). Reading goes wherever Sailjail lets the app read (see Permissions in
 * harbour-weight-tracker.desktop), so a backup picked from Downloads or a memory card
 * can be restored.
 */
class FileWriter : public QObject
{
    Q_OBJECT

public:
    explicit FileWriter(QObject *parent = 0);

    // ~/Documents/WeightTracker -- created on demand. Empty string if it cannot be created.
    Q_INVOKABLE QString exportDirectory();

    // ~/Documents/Health -- created on demand, where Health looks for backups.
    Q_INVOKABLE QString healthDirectory();

    // <private data>/backups -- created on demand. Copies no other app can read.
    Q_INVOKABLE QString backupDirectory();

    Q_INVOKABLE bool writeFile(const QString &path, const QString &content);
    Q_INVOKABLE QString readFile(const QString &path);
    Q_INVOKABLE bool removeFile(const QString &path);

    // Files in dirPath ending in suffix, newest first. Absolute paths.
    Q_INVOKABLE QStringList listFiles(const QString &dirPath, const QString &suffix);

    // {exists, size, modified}: size in bytes, modified in milliseconds since the epoch.
    Q_INVOKABLE QVariantMap fileInfo(const QString &path);

    // Human readable reason for the last false/empty return value.
    Q_INVOKABLE QString lastError() const;

private:
    QString documentsSubdirectory(const QString &name);
    bool mayWrite(const QString &path);

    QString m_lastError;
};

#endif // FILEWRITER_H
