/*
 * Weight Tracker for SailfishOS
 * Copyright (C) 2021-2026 Adel Noureddine
 * Licensed under the GNU GPL 3 license only (GPL-3.0-only).
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QCoreApplication>
#include <QGuiApplication>
#include <QLocale>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>
#include <QTranslator>
#include <QtQml>

#include <sailfishapp.h>

#include "filewriter.h"
// APP_VERSION, written by qmake into the build folder (src/version.h.in).
#include "version.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    /*
     * These must match [X-Sailjail] in harbour-weight-tracker.desktop: Sailjail only
     * grants write access to ~/.local/share/<OrganizationName>/<ApplicationName>, and
     * QtQuick.LocalStorage keeps the database there.
     *
     * "WeighTracker" is misspelt on purpose. Version 1.3 shipped with that name in its
     * desktop file, so that is the folder every existing user's data is in; correcting
     * the spelling would leave them with an empty app.
     */
    QCoreApplication::setOrganizationName(QStringLiteral("org.noureddine"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("org.noureddine"));
    QCoreApplication::setApplicationName(QStringLiteral("WeighTracker"));
    QCoreApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

    // sailfishapp_i18n installs the compiled catalogues next to the QML. Without one for
    // the phone's language, the base catalogue still gives the English plural forms
    // ("3 days", not "3 day(s)"): the other English texts are the source texts.
    const QString translations = SailfishApp::pathTo(QStringLiteral("translations")).toLocalFile();
    QScopedPointer<QTranslator> translator(new QTranslator);
    if (translator->load(QStringLiteral("harbour-weight-tracker-") + QLocale::system().name(), translations)
            || translator->load(QStringLiteral("harbour-weight-tracker"), translations)) {
        app->installTranslator(translator.data());
    }

    qmlRegisterType<FileWriter>("harbour.weight.tracker.FileWriter", 1, 0, "FileWriter");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"),
                                            QStringLiteral(APP_VERSION));
    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
