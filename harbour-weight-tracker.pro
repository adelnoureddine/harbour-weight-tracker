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

CONFIG += sailfishapp

SOURCES += src/harbour-weight-tracker.cpp

DISTFILES += qml/harbour-weight-tracker.qml \
    qml/cover/CoverPage.qml \
    qml/pages/About.qml \
    qml/pages/AddMetric.qml \
    qml/pages/FirstPage.qml \
    qml/pages/History.qml \
    qml/pages/Profile_Settings.qml \
    rpm/harbour-weight-tracker.changes \
    rpm/harbour-weight-tracker.changes.run.in \
    rpm/harbour-weight-tracker.spec \
    rpm/harbour-weight-tracker.yaml \
    translations/*.ts \
    harbour-weight-tracker.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
# TRANSLATIONS += translations/harbour-weight-tracker-de.ts
