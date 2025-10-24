module ApplicationHelper
    def full_title(page_title = "")
        base_title = "Restaurant Reservation "
        if page_title.empty?
            base_title
        else
            page_title.capitalize + " | " + base_title
        end
    end
end
