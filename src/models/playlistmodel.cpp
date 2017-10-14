#include "playlistmodel.h"

#include "../track.h"
#include "../dbadapter.h"

#include <QSqlDatabase>
#include <QSqlQuery>

PlayListModel::PlayListModel(QObject *parent) :
    QAbstractListModel(parent)
{
    hash.insert(Qt::UserRole ,QByteArray("trackId"));
    hash.insert(Qt::UserRole+1 ,QByteArray("artist"));
    hash.insert(Qt::UserRole+2 ,QByteArray("title"));
    hash.insert(Qt::UserRole+3 ,QByteArray("fileName"));
    hash.insert(Qt::UserRole+4 ,QByteArray("played"));
}

void PlayListModel::addItem(int trackId, int count)
{
    Track *track = Track::toId(trackId);
    if(!track)
    {
        return;
    }

    playListItem item;
    item.trackId = trackId;
    item.artist = track->getArtistName();
    item.title = track->getTitle();
    item.fileName = track->getFileName();

    if(count == 0)
    {
        count = playList.size();
    }

    insertRows(count,1,item);


    QSqlDatabase db = dbAdapter::instance().db;
    QSqlQuery query(db);
    query.prepare("INSERT INTO playlist (`song_id`, `time`) VALUES ( :trackid , 0)");
    query.bindValue(":trackid",trackId);
    query.exec();

    qDebug() << "Add " << item.artist << "" << item.title << item.fileName;

}

int PlayListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return playList.count();
}


QVariant PlayListModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(role);
    if (!index.isValid())
        return QVariant();

    if (index.row() >= playList.size())
        return QVariant();
    playListItem item = playList.at(index.row());
    if(role == Qt::UserRole)
    {
        return item.trackId;
    }
    else if(role == Qt::UserRole+1)
    {
        return item.artist;
    }
    else if(role == Qt::UserRole+2)
    {
        return item.title;
    }
    else if(role == Qt::UserRole+3)
    {
        return item.fileName;
    }
    else if(role == Qt::UserRole+4)
    {
        return item.played;
    }
    return QVariant();
}

bool PlayListModel::insertRows(int position, int rows, playListItem &item, const QModelIndex &parent)
{
    Q_UNUSED(parent);

    beginInsertRows(QModelIndex(), position, position+rows-1);
    for (int row = 0; row < rows; ++row) {
        playList.insert(position, item);
    }
    endInsertRows();
    return true;
}


bool PlayListModel::removeRows(int position, int rows, const QModelIndex &index)
{
    Q_UNUSED(index);
    if((position+rows) > playList.count())
    {
        return false;
    }

    beginRemoveRows(QModelIndex(), position, position+rows-1);
    for (int row = 0; row < rows; ++row) {
        playList.removeAt(position);
    }
    endRemoveRows();
    return true;
}

QVariant PlayListModel::get(int idx)
{
    if(idx >= playList.size())
    {
        return QVariant();
    }

    QMap<QString, QVariant> itemData;
    playListItem item = playList.at(idx);

    itemData.insert("trackId",item.trackId);
    itemData.insert("artist",item.artist);
    itemData.insert("title",item.title);
    itemData.insert("fileName",item.fileName);
    itemData.insert("played",item.played);

    return QVariant(itemData);
}

void PlayListModel::remove(int idx)
{
    removeRows(idx,1);
}

void PlayListModel::clearPlaylist()
{
    qDebug() << "Clear playlist";
    playList.clear();

    QSqlDatabase db = dbAdapter::instance().db;
    QSqlQuery query(db);
    query.prepare("DELETE FROM playlist WHERE time = 0");
    bool ok = query.exec();

    if(!ok)
    {
        qDebug() << query.lastQuery() << query.lastError().text();
    }
}

void PlayListModel::loadPlaylistFromDB()
{
    QSqlDatabase db = dbAdapter::instance().db;
    QSqlQuery query(db);
    query.prepare("SELECT song_id FROM playlist WHERE time = 0 LIMIT 5");
    bool ok = query.exec();

    if(!ok)
    {
        qDebug() << query.lastQuery() << query.lastError().text();
    }
    else
    {
        while(query.next())
        {
            addItem(query.value(0).toInt());
        }
    }
}

void PlayListModel::formatRandomPlaylist(const int tracksCount)
{
    qDebug() << "Format random playlist";

    QSqlDatabase db = dbAdapter::instance().db;
    QSqlQuery query(db);
    query.prepare("SELECT id FROM tracks ORDER BY RANDOM() LIMIT :limit");
    query.bindValue(":limit",tracksCount);
    bool ok = query.exec();

    if(!ok)
    {
        qDebug() << query.lastQuery() << query.lastError().text();
    }
    else
    {
        while(query.next())
        {
            addItem(query.value(0).toInt());
        }
    }
}

void PlayListModel::formatAutoPlaylist()
{
    uint songRepeat = 60*60;
    uint artistRepeat = 3*60*60;

    int smartSong = 10; //How many songs add to playlist
    int errors = 0;     //num of errors
    int buildRepear = 8;//max repeat of find song

    for(int i=0; i < smartSong; i++)
    {
        if(errors > buildRepear)
        {
            break;
        }

        QString s_notin = QString("0");
        QString a_notin = QString("0");

        foreach (playListItem item, playList) {
            s_notin.append(","+item.trackId);
        }

        QSqlDatabase db = dbAdapter::instance().db;
        QSqlQuery query(db);

        //create played artist list
        query.prepare("SELECT tracks.artist_id \
                      FROM tracks \
                      INNER JOIN playlist ON tracks.id = playlist.song_id \
                WHERE ptime < :atime");
                query.bindValue(":atime",QDateTime().toTime_t()-artistRepeat);

                if(query.next())
        {
            a_notin.append(",");
            a_notin.append(query.value(0).toString());
        }

        //create songs list
        query.prepare("SELECT tracks.id,\
                      playlist.time as ptime \
                      FROM tracks \
                      LEFT OUTER JOIN playlist ON tracks.id = playlist.song_id \
                WHERE ptime < :stime OR ptime IS NULL \
                AND tracks.id NOT IN (:s_notin) \
                AND artist_id NOT IN (:a_notin) \
                ORDER BY RANDOM()");

                query.bindValue(":stime",QDateTime().toTime_t()-songRepeat);
                query.bindValue(":s_notin",s_notin);
        query.bindValue(":a_notin",a_notin);

        bool ok = query.exec();
        if(!ok)
        {
            qDebug() << query.lastQuery() << query.lastError().text();
        }

        if(query.next())
        {
            addItem(query.value(0).toInt());
        }
        else
        {
            errors++;
            i++;
        }
    }

    if(playList.count() < smartSong)
    {
        formatRandomPlaylist(playList.count()-smartSong);
    }
}

void PlayListModel::setPlayed(int idx, const QModelIndex &parent)
{
    Q_UNUSED(parent);

    if(idx > playList.count())
    {
        return;
    }

    for (int row = 0; row < playList.count(); ++row)
    {
        playList[row].played = false;
        dataChanged(index(row),index(row));
    }

    playList[idx].played = true;
    dataChanged(index(idx),index(idx));

    //add to database
    QVariant track = get(idx);
    int track_id = track.toMap().find("trackId").value().toInt();

    qDebug() << "Play trackID" << track_id;

    QSqlDatabase db = dbAdapter::instance().db;
    QSqlQuery query(db);
    query.prepare("INSERT INTO playlist (`song_id`, `time`) VALUES ( :trackid , :time)");
    query.bindValue(":trackid",track_id);
    query.bindValue(":time", QDateTime().toTime_t());

    bool ok = query.exec();
    if(!ok)
    {
        qDebug() << query.lastQuery() << query.lastError().text();
    }
}