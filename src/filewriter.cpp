/*
 * Weight Tracker for SailfishOS
 * Copyright (C) 2021-2026 Adel Noureddine
 * Licensed under the GNU GPL 3 license only (GPL-3.0-only).
 */

#include "filewriter.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTextStream>

namespace {

// A backup of years of weights is well under a megabyte. Anything far beyond that is
// not one, and reading it into a string would only exhaust the phone's memory.
const qint64 MaximumReadSize = 16 * 1024 * 1024;

const char ExportFolder[] = "WeightTracker";
const char HealthFolder[] = "Health";
const char BackupFolder[] = "backups";

QString ensureDirectory(const QString &parent, const QString &name)
{
    if (parent.isEmpty()) {
        return QString();
    }
    QDir dir(parent);
    if (!dir.exists(name) && !dir.mkpath(name)) {
        return QString();
    }
    return dir.filePath(name);
}

}

FileWriter::FileWriter(QObject *parent)
    : QObject(parent)
{
}

QString FileWriter::documentsSubdirectory(const QString &name)
{
    m_lastError.clear();

    const QString documents = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (documents.isEmpty()) {
        m_lastError = tr("No documents folder is available.");
        return QString();
    }

    const QString directory = ensureDirectory(documents, name);
    if (directory.isEmpty()) {
        m_lastError = tr("Could not create %1").arg(QDir(documents).filePath(name));
    }
    return directory;
}

QString FileWriter::exportDirectory()
{
    return documentsSubdirectory(QLatin1String(ExportFolder));
}

QString FileWriter::healthDirectory()
{
    return documentsSubdirectory(QLatin1String(HealthFolder));
}

QString FileWriter::backupDirectory()
{
    m_lastError.clear();

    const QString data = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString directory = data.isEmpty() || !QDir().mkpath(data)
                              ? QString() : ensureDirectory(data, QLatin1String(BackupFolder));
    if (directory.isEmpty()) {
        m_lastError = tr("Could not create %1").arg(QDir(data).filePath(QLatin1String(BackupFolder)));
    }
    return directory;
}

/*
 * Whether `path` is a file directly inside one of the folders the app writes to. The
 * folder is compared by its canonical path, so "..", a link to elsewhere or a path QML
 * built wrongly cannot reach any other place, and an existing link is never followed.
 */
bool FileWriter::mayWrite(const QString &path)
{
    const QFileInfo info(path);
    const QString parent = QFileInfo(info.absolutePath()).canonicalFilePath();
    if (parent.isEmpty() || info.fileName().isEmpty() || info.isSymLink() || info.isDir()) {
        return false;
    }

    QStringList allowed;
    const QString documents = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (!documents.isEmpty()) {
        allowed << QDir(documents).filePath(QLatin1String(ExportFolder))
                << QDir(documents).filePath(QLatin1String(HealthFolder));
    }
    const QString data = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!data.isEmpty()) {
        allowed << QDir(data).filePath(QLatin1String(BackupFolder));
    }
    for (int i = 0; i < allowed.count(); ++i) {
        const QString canonical = QFileInfo(allowed.at(i)).canonicalFilePath();
        if (!canonical.isEmpty() && canonical == parent) {
            return true;
        }
    }
    return false;
}

bool FileWriter::writeFile(const QString &path, const QString &content)
{
    m_lastError.clear();

    if (!mayWrite(path)) {
        m_lastError = tr("This location is not allowed.");
        return false;
    }

    // Written to a temporary file and renamed into place on commit(), so a full disk
    // or a crash mid-write cannot leave a truncated backup behind.
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        m_lastError = file.errorString();
        return false;
    }

    QTextStream out(&file);
    out.setCodec("UTF-8");
    out << content;
    out.flush();

    if (out.status() != QTextStream::Ok || file.error() != QFile::NoError) {
        m_lastError = file.errorString();
        file.cancelWriting();
        return false;
    }

    if (!file.commit()) {
        m_lastError = file.errorString();
        return false;
    }
    return true;
}

QString FileWriter::readFile(const QString &path)
{
    m_lastError.clear();

    QFile file(path);
    if (file.size() > MaximumReadSize) {
        m_lastError = tr("This file is too large to be a backup.");
        return QString();
    }
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_lastError = file.errorString();
        return QString();
    }

    QTextStream in(&file);
    in.setCodec("UTF-8");
    const QString content = in.readAll();
    file.close();
    return content;
}

bool FileWriter::removeFile(const QString &path)
{
    m_lastError.clear();

    if (!mayWrite(path)) {
        m_lastError = tr("This location is not allowed.");
        return false;
    }
    QFile file(path);
    if (!file.exists()) {
        return true;
    }
    if (!file.remove()) {
        m_lastError = file.errorString();
        return false;
    }
    return true;
}

QStringList FileWriter::listFiles(const QString &dirPath, const QString &suffix)
{
    m_lastError.clear();

    QDir dir(dirPath);
    if (!dir.exists()) {
        m_lastError = tr("%1 does not exist.").arg(dirPath);
        return QStringList();
    }

    QStringList filters;
    filters << (QStringLiteral("*") + suffix);

    QStringList paths;
    const QFileInfoList entries = dir.entryInfoList(filters, QDir::Files | QDir::Readable, QDir::Time);
    for (int i = 0; i < entries.count(); ++i) {
        paths.append(entries.at(i).absoluteFilePath());
    }
    return paths;
}

QVariantMap FileWriter::fileInfo(const QString &path)
{
    const QFileInfo info(path);
    QVariantMap map;
    map.insert(QStringLiteral("exists"), info.exists() && info.isFile());
    map.insert(QStringLiteral("size"), info.exists() ? double(info.size()) : 0.0);
    map.insert(QStringLiteral("modified"),
               info.exists() ? double(info.lastModified().toMSecsSinceEpoch()) : 0.0);
    return map;
}

QString FileWriter::lastError() const
{
    return m_lastError;
}
