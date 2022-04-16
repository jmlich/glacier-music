import QtQuick 2.6

import QtQuick.Controls 1.0
import QtQuick.Controls.Nemo 1.0
import QtQuick.Controls.Styles.Nemo 1.0
import QtQuick.Window 2.1
import QtQuick.Layouts 1.0

import QtMultimedia 5.5

import org.nemomobile.settings 1.0
import org.nemomobile.mpris 1.0

import org.glacier.music.collection 1.0
import org.glacier.music.playlistmodel 1.0
import org.glacier.music.cover 1.0

import Nemo.Dialogs 1.0

import "pages"

ApplicationWindow {
    id: root

    property int cameraId: 0
    property string fileName: ""

    property var iso;

    Settings{
        id: settings;
    }

    Collection{
        id: collection
    }

    PlaylistModel{
        id: nextTrackModel
        Component.onCompleted: {
            loadPlaylistFromDB();
            nextTrackModel.currentIndex = 0
        }
    }

    Cover{
        id: coverLoader
    }

    MediaPlayer{
        id: rootAudio

        function statusToStr(st) {
            switch (st) {
            case MediaPlayer.NoMedia: return "no media has been set.";
            case MediaPlayer.Loading: return "the media is currently being loaded."
            case MediaPlayer.Loaded: return "the media has been loaded."
            case MediaPlayer.Buffering: return "the media is buffering data."
            case MediaPlayer.Stalled: return "playback has been interrupted while the media is buffering data."
            case MediaPlayer.Buffered: return "the media has buffered data."
            case MediaPlayer.EndOfMedia: return "the media has played to the end."
            case MediaPlayer.InvalidMedia: return "the media cannot be played."
            default:
            case MediaPlayer.UnknownStatus: return "the status of the media is unknown"
            }
        }

        onStatusChanged: {
            console.log("rootAudio.status " + statusToStr(status) + " " + source)
        }

        onVolumeChanged: {
            settings.setValue("volume",volume);
            settings.sync();
        }

        onPositionChanged: {
            if(rootAudio.playbackState == MediaPlayer.PlayingState){
                settings.setValue("seek",position);
            }
        }

        onPlaybackStateChanged: {
            settings.setValue("playbackState",rootAudio.playbackState);
        }

        Component.onCompleted: {
            volume = settings.value("volume",1)
        }
    }

    initialPage: PlayerPage{}

    Component.onCompleted: {
        if(collection.isFirstRun())
        {
            pageStack.push(Qt.resolvedUrl("../pages/SettingsPage.qml"));
        }
        collection.rescanCollection()
        nextTrackModel.loadPlaylistFromDB()
    }

    Rectangle{
        id: rescanProgress
        width: parent.width
        height: Theme.itemHeightExtraSmall/10
        color: Theme.accentColor
        visible: false;
        anchors.top: root.top
    }

    Connections{
        target: collection
        onUpdateRescanProgress: {
            if(prc < 100)
            {
                rescanProgress.width = root.width*(prc/100);
                rescanProgress.visible = true;
            }
            else
            {
                rescanProgress.visible = false;
            }
        }
        onNoMusicFiles: {
            noMusicDialog.visible = true
        }
    }

    MprisPlayer {
        id: mprisPlayer

        property string artist: qsTr("Loading")
        property string song: qsTr("tags...")

        serviceName: "glacier-music"
        identity: "Glacier Music"
        supportedUriSchemes: ["file"]
        supportedMimeTypes: ["audio/x-wav", "audio/x-vorbis+ogg", "audio/mpeg"]

        canControl: true

        canGoNext: true
        canGoPrevious: true
        canPause: rootAudio.playbackState == MediaPlayer.PlayingState
        canPlay: rootAudio.playbackState != MediaPlayer.PlayingState
        canSeek: false

        playbackStatus: (rootAudio.playbackState == MediaPlayer.PlayingState) ? Mpris.Playing : Mpris.Paused

        onArtistChanged: {
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.Artist)] = [artist] // List of strings
            mprisPlayer.metadata = metadata
        }

        onSongChanged: {
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.Title)] = song // String
            mprisPlayer.metadata = metadata
        }
    }

    QueryDialog {
        id: noMusicDialog
        visible: false
        inline: false

        icon: "image://theme/exclamation-triangle"

        cancelText: qsTr("Cancel")
        acceptText: qsTr("Ok")
        headingText: qsTr("No music files found")
        subLabelText: qsTr("Please add music files into Music or Download directory. Or connect card with music")

        onSelected: {
            Qt.quit()
        }
    }
}
