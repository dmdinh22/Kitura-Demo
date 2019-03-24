import SwiftKuery
import SwiftKuerySQLite

class AlbumTable: Table {
    let tableName = "Album"
    let AlbumId = Column("AlbumId")
    let Title = Column("Title")
}

class TrackTable: Table {
    let tableName = "Track"
    let Name = Column("Name")
    let AlbumId = Column("AlbumId")
    let Composer = Column("Composer")
}
