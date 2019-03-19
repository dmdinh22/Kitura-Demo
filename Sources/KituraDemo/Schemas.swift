import SwiftKuery
import SwiftKuerySQLite

class Album: Table {
    let tableName = "Album"
    let AlbumId = Column("AlbumId")
    let Title = Column("Title")
}

class Track: Table {
    let tableName = "Track"
    let Name = Column("Name")
    let AlbumId = Column("AlbumId")
    let Composer = Column("Composer")
}
