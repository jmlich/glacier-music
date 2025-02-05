/*
 * Copyright (C) 2021-2022 Chupligin Sergey <neochapay@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

import QtQuick
import Nemo.Controls

import QtMultimedia

Item{
    id: controsArea
    height: Theme.itemHeightHuge

    Image{
        id: playlistBtn
        width: playPauseBtn.width*0.6
        height: width

        anchors{
            right: backBtn.left
            rightMargin: width
            verticalCenter: playPauseBtn.verticalCenter
        }

        MouseArea{
            anchors.fill: parent
            onClicked: {
                pageStack.push(Qt.resolvedUrl("../pages/PlayListPage.qml"));
            }
        }

        source: "image://theme/align-justify"
    }

    Image{
        id: backBtn
        width: playPauseBtn.width*0.6
        height: width

        anchors{
            right: playPauseBtn.left
            rightMargin: width/2
            verticalCenter: playPauseBtn.verticalCenter
        }

        MouseArea{
            anchors.fill: parent
            onClicked: playPrev()
        }

        source: "image://theme/backward"
    }

    Image{
        id: playPauseBtn
        width: height
        height: parent.height*0.9

        anchors.centerIn: parent;

        source: (rootAudio.playbackState == MediaPlayer.PlayingState) ?
                    "image://theme/pause" :
                    "image://theme/play"

        MouseArea{
            anchors.fill: parent
            onClicked: playPause();
        }
    }

    Image{
        id: forwBtn
        width: playPauseBtn.width*0.6
        height: width

        anchors{
            left: playPauseBtn.right
            leftMargin: width/2
            verticalCenter: playPauseBtn.verticalCenter
        }

        source: "image://theme/forward"

        MouseArea{
            anchors.fill: parent
            onClicked: playNext()
        }
    }

    Image{
        id: soundBtn
        width: playPauseBtn.width*0.6
        height: width

        anchors{
            left: forwBtn.right
            leftMargin: width
            verticalCenter: playPauseBtn.verticalCenter
        }

        source: "image://theme/volume-up"

        MouseArea{
            anchors.fill: parent
            onClicked: {
                volumeArea.visible = true
                removeVolumeTimer.start()
            }
        }
    }

    Rectangle{
        id: volumeArea
        width: parent.width
        height: parent.height

        color: Theme.backgroundColor

        visible: false

        MouseArea{
            anchors.fill: parent
            onClicked: volumeArea.visible = false
        }

        Slider{
            id: volumeSlider

            width: parent.width*0.8
            anchors.centerIn: parent

            from: 0
            to: 1
            stepSize: 0.05
            value: rootAudio.volume

            onValueChanged:{
                removeVolumeTimer.restart()
                rootAudio.volume = value
            }
        }
    }

    Timer{
        id: removeVolumeTimer
        interval: 5000
        onTriggered: {
            volumeArea.visible = false
        }
    }
}
