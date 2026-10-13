import WidgetKit
import SwiftUI

@main
struct WaypointsWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecentlySavedWidget()
        FavoriteDestinationWidget()
        UpcomingTripWidget()
        UnconfirmedDiscoveriesWidget()
    }
}
