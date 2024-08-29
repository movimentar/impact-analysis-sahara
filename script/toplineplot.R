#' Generate a Time Series Line Plot
#'
#' This function creates a line plot to visualize trends over time. It allows for flexible customization of appearance and date formatting.
#'
#' @param df The dataframe containing the time series data.
#' @param time_variable The name of the column in `df` representing the time variable (as a character string). Defaults to "submission_time".
#' @param y_label The label for the y-axis (as a character string). Defaults to "Number of submissions".
#' @param date_breaks The frequency at which to display date labels on the x-axis (e.g., "1 day", "1 week", "1 month"). Defaults to "1 day".
#' @param date_labels The format of date labels using standard date formatting codes (e.g., "%d/%m/%y" for day/month/year). Defaults to "%d/%m/%y".
#' @param title The title of the plot (as a character string). Defaults to "Submissions by date".
#' @param units The unit of the y-axis variable (as a character string). Defaults to " submissions".
#' @param point_colour The color of the data points on the line. Defaults to "darkred".
#' @param line_colour The color of the line. Defaults to "pink".
#' @param line_size The width of the line. Defaults to 2.
#' @param label_size The font size of the axis labels. Defaults to 11.
#' @param title_break The width at which to wrap the title to a new line. Defaults to 60 characters.
#' @param simplify_dates Whether to simplify dates to the first of the month. Defaults to FALSE.
#' @param label_angle The angle to rotate x-axis labels. Defaults to 70 degrees.
#'
#' @return A ggplot object representing the time series line plot.
#' @export
#'
#' @examples
#' toplineplot(df = your_data, time_variable = "date_column")

toplineplot <- function(df, time_variable = "submission_time", y_label = "Number of submissions", 
                        date_breaks = "1 day", date_labels = "%d/%m/%y", title = "Submissions by date",
                        units = " submissions", point_colour = "darkred", line_colour = "pink",
                        line_size = 2, label_size = 11, title_break = 60, simplify_dates = FALSE,
                        label_angle = 70) {
  
  if (nrow(df) > 0) {
    
    if (simplify_dates) {
      df <- df %>%
        dplyr::select(dplyr::all_of(time_variable)) %>%
        tidyr::drop_na() %>%
        unlist() %>%
        as.Date(.) %>%
        format("%Y-%m-01") %>% lubridate::ymd() %>%
        tibble::as_tibble() %>%
        dplyr::group_by(value) %>%
        dplyr::reframe(Submissions = dplyr::n()) %>%
        dplyr::ungroup() %>%
        dplyr::rename(Date = value)
    } else {
      df <- df %>%
        dplyr::select(dplyr::all_of(time_variable)) %>%
        tidyr::drop_na() %>%
        unlist() %>%
        as.Date(.) %>% lubridate::ymd() %>%
        tibble::as_tibble() %>%
        dplyr::group_by(value) %>%
        dplyr::reframe(Submissions = dplyr::n()) %>%
        dplyr::ungroup() %>%
        dplyr::rename(Date = value)
    }
    
    ## Prepare plot
    ggplot2::ggplot(df, ggplot2::aes(Date, Submissions)) +
      ## Sets theme/design
      ggplot2::theme_linedraw() +
      ## Defines geometry: line
      ggplot2::geom_line(colour = line_colour, linewidth = line_size) +
      ## Defines geometry: points
      ggplot2::geom_point(colour = point_colour) +
      ## Removes label of x-axis
      ggplot2::xlab("") +
      ## Sets label for y-axis
      ggplot2::ylab(y_label) +
      # Changes format of dates in the plot display
      ggplot2::scale_x_date(date_labels = date_labels, date_breaks = date_breaks) +
      # Sets options font formatting options
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(
          colour = "grey20", size = label_size, angle = label_angle, hjust = .5, vjust = .5, face = "plain"),
        axis.text.y = ggplot2::element_text(
          colour = "grey20", size = label_size, angle = 0, hjust = 1, vjust = 0, face = "plain"),
        axis.title.y = ggplot2::element_text(
          colour = "grey20", size = label_size, angle = 90, hjust = .5, vjust = .5, face = "plain"),
        plot.title = ggplot2::element_text(size = 14, face = "bold", vjust = 1.2),
        plot.subtitle = ggplot2::element_text(size = 12)) +
      ## Sets title and subtitle
      ggplot2::ggtitle(stringr::str_wrap(title, width = title_break),
                       subtitle = paste("n =", 
                                        format(sum(df$Submissions)), units, 
                                        "between",
                                        min(df$Date) %>% format(date_labels), "and",
                                        max(df$Date) %>% format(date_labels), sep = " ")) +
      # Adjust scales to integer numbers
      ggplot2::scale_y_continuous(
        breaks = function(x) unique(floor(pretty(seq(0, (max(x) + 1) * 1.1))))
      ) +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                     panel.grid.major = ggplot2::element_line(colour = "grey", size = 0.25))
    
  } else {
    cat(paste("''", title, "''"), fill = TRUE, labels = paste0("Data is not available"))
  }
}

