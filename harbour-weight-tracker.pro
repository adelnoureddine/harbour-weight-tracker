# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-weight-tracker

# The version shown on the About page. A package build passes the RPM's own version
# (QMakeOptions in rpm/harbour-weight-tracker.yaml), so the two cannot differ; the
# value here is only for a build run by hand.
isEmpty(APP_VERSION): APP_VERSION = 2.0

# It reaches the code through a header written into the build folder (see
# src/version.h.in for why it is not a -D option).
version_header.input = $$PWD/src/version.h.in
version_header.output = $$OUT_PWD/version.h
QMAKE_SUBSTITUTES += version_header
INCLUDEPATH += $$OUT_PWD
DEPENDPATH += $$OUT_PWD

CONFIG += sailfishapp sailfishapp_i18n c++11

SOURCES += \
    src/harbour-weight-tracker.cpp \
    src/filewriter.cpp

HEADERS += \
    src/filewriter.h

OTHER_FILES += \
    src/version.h.in

TRANSLATIONS += \
    translations/harbour-weight-tracker.ts \
    translations/harbour-weight-tracker-fr.ts

DISTFILES += \
    qml/harbour-weight-tracker.qml \
    qml/cover/CoverPage.qml \
    qml/components/BmiScale.qml \
    qml/components/Card.qml \
    qml/components/CardBackground.qml \
    qml/components/ChartCard.qml \
    qml/components/ChartRangeSelector.qml \
    qml/components/ChartStats.qml \
    qml/components/HistoryHero.qml \
    qml/components/LinkRow.qml \
    qml/components/MetricChart.qml \
    qml/components/Sparkline.qml \
    qml/components/StatusLine.qml \
    qml/components/StatusPill.qml \
    qml/icons/bmi.svg \
    qml/icons/height.svg \
    qml/icons/weight.svg \
    qml/js/Database.js \
    qml/js/HealthExport.js \
    qml/js/bmi.js \
    qml/js/utils.js \
    qml/pages/AboutPage.qml \
    qml/pages/BmiPage.qml \
    qml/pages/DataPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/PickBackupPage.qml \
    qml/pages/ProfileDialog.qml \
    qml/pages/ProfilesPage.qml \
    qml/pages/TargetDialog.qml \
    qml/pages/WeightDialog.qml \
    qml/pages/WeightPage.qml \
    rpm/harbour-weight-tracker.changes \
    rpm/harbour-weight-tracker.spec \
    rpm/harbour-weight-tracker.yaml \
    harbour-weight-tracker.desktop \
    LICENSE

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
