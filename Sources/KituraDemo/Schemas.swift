import SwiftKuery
import SwiftKuerySQLite

class Album: Table {
    let tableName = "Album"
    let Title = Column("Title")
}
