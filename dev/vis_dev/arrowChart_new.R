#' Arrow Chart for The Mark USA
#'
#' [arrowChart()] creates an pre-post arrow chart of group averages and returns
#' a ggplot object.
#'
#' @param df Required, a [tibble][tibble::tibble-package] or data frame of **numeric** data that also has a categorical group
#'  variable to split up the data, e.g. role, gender, education level, etc. must be in 5 point scales and pre-post.
#'
#' @param scale_labels Required, a character vector of labels for the response scale, must be in the desired order,
#'    e.g. if you have a 5 item scale of minimal to extensive it should look like this: `levels_min_ext <- c("Minimal", "Slight", "Moderate", "Good", "Extensive")`.
#'    This argument accepts a character vector of 3 to 7 items.
#'
#' @param group_colors Required, a character vector of hex codes for colors to associate
#'   each group to, e.g. this data has two groups and this function creates an
#'   overall group so this function will need a 'group_colors' character vector of
#'   three colors. 'group_colors' need to be in the order you want them associated to
#'   the group based on the factor levels for the group variable, last color
#'   will be the overall group of "all".
#'
#' @param overall_n Logical, default is FALSE. If TRUE, returns an overall *n* for all questions that is in the upper left tag of the plot.
#'    If False, adds *n* to each question/item after the respective labels.
#'
#' @param question_labels Default is NULL. Takes in a named character vector to both supply labels the questions and sort the order of the questions.
#'    The named character vector should have the new labels as the "name" and the old labels as the "variable" sorted in the
#'    desired order of appearing in the plot, first item will appear at the top of the plot. See examples.
#'
#' @param question_order Logical, default is FALSE. If TRUE, the question order will be taken from the user supplied named character vector passed to
#'    question_labels, where the first item will be at the top of the plot and so on. If FALSE, the question order will be the questions with highest
#'    post score average on the top of the plot descending.
#'
#' @return A [ggplot2][ggplot2::ggplot2-package] object that plots the items into a arrow bar chart.
#' @export
#'
#' @examples
#' items <- dplyr::tibble(
#'   pre_Organization = c(1, 2, 3, 4, 5, 4, 3, 2, 1),
#'   post_Organization = dplyr::if_else(pre_Organization < 5, pre_Organization + 1, pre_Organization),
#'   pre_Source = c(2, 2, 3, 5, 4, 3, 2, 1, 2),
#'   post_Source = dplyr::if_else(pre_Source < 4, pre_Source + 2, pre_Source),
#'   pre_Publish = c(1, 1, 1, 2, 2, 2, 3, 3, 3),
#'   post_Publish = pre_Publish + 2,
#'   pre_Write = c(2, 2, 2, 3, 3, 3, 4, 4, 4),
#'   post_Write = pre_Write + 1,
#'   pre_Research = c(1, 1, 2, 2, 3, 3, 4, 4, 4),
#'   post_Research = pre_Research + 1,
#'   group = factor(c(
#'       "grad", "undergrad", "grad", "undergrad", "grad",
#'       "undergrad", "undergrad", "grad", "undergrad"
#'  ), levels = c("grad", "undergrad"))
#' )
#' # Labels for response scales to recode the numeric variables to on the plot:
#' levels_min_ext <- c("Minimal", "Slight", "Moderate", "Good", "Extensive")
#' # Question labels as a named vector with the naming structure
#' # like this: c("{new label}" = "{original variable name}"):
#' question_labels <- c("Publish a lot of high quality papers" =  "Publish",
#'                      "Write a lot of research papers" = "Write",
#'                      "Research in a lab with faculty" = "Research",
#'                      "Organization of a large research project" = "Organization",
#'                      "Source work for a research paper" = "Source")
#'
#' # Set up a character vector of scale colors to pass to the argument group_colors:
#' threeScale_theMark_colors <- c("#79AB53", "#4B9FA6", "#2C2C4F")
#'
#' # Example with n for each question and original labels:
#' arrowChart(df = items, scale_labels = levels_min_ext, group_colors = threeScale_theMark_colors,
#'     overall_n = FALSE, question_labels = NULL, question_order = FALSE)
#'
#' # With new labels, question_order = FALSE, and overall_n set to TRUE:
#' arrowChart(df = items, scale_labels = levels_min_ext, group_colors = threeScale_theMark_colors,
#'     overall_n = FALSE, question_labels = question_labels, question_order = FALSE)
#'
#' # With new labels and order taken from question_labels argument, and overall_n set to FALSE:
#' arrowChart(df = items, scale_labels = levels_min_ext, group_colors = threeScale_theMark_colors,
#'     overall_n = FALSE, question_labels = question_labels, question_order = TRUE)
arrowChart_new <- function(df, scale_labels, group_colors, overall_n = FALSE, question_labels = NULL, question_order = FALSE) {
  extrafont::loadfonts("all", quiet = TRUE)

  . <- NULL

  # Set up a df for the original groups separate average:
  arrow_df_group <- {{ df }} %>%
    dplyr::group_by(.data$group) %>%
    tidyr::pivot_longer(-"group", names_to = "question", values_to = "response") %>%
    dplyr::mutate(group = factor(.data$group)) %>%
    tidyr::separate(.data$question, into = c("timing", "question"), sep = "_") %>%
    dplyr::group_by(.data$group, .data$question, .data$timing) %>%
    dplyr::mutate(timing = factor(.data$timing, levels = c("pre", "post"))) %>%
    dplyr::summarize(score_avg = mean(.data$response, na.rm = TRUE), .groups = "keep") %>%
    dplyr::ungroup()

  # Set up a df for an overall average
  arrow_df_all <- {{ df }} %>%
    dplyr::select(!"group") %>%
    tidyr::pivot_longer(tidyselect::everything(), names_to = "question", values_to = "response") %>%
    tidyr::separate(.data$question, into = c("timing", "question"), sep = "_") %>%
    dplyr::group_by(.data$question, .data$timing) %>%
    dplyr::mutate(timing = factor(.data$timing, levels = c("pre", "post"))) %>%
    dplyr::summarize(score_avg = mean(.data$response, na.rm = TRUE), .groups = "keep") %>%
    dplyr::ungroup() %>%
    dplyr::mutate(group = "all")

  # Full join the data by groups and overall:
  arrow_df <- dplyr::full_join(arrow_df_group, arrow_df_all, by = dplyr::join_by("group", "question", "timing", "score_avg")) %>%
    dplyr::group_by(.data$group, .data$question, .data$timing) %>%
    dplyr::mutate(
      group = forcats::fct_rev(factor(.data$group)) # Rev the factor order of "group":
    ) %>%
    dplyr::ungroup() %>%
      tidyr::pivot_wider( # pivot wider to add a difference in `score_avg` column
          id_cols = tidyselect::everything(),
          names_from = tidyselect::all_of(c("timing")),
          values_from = tidyselect::all_of(c("score_avg")),
          names_glue = "{timing}_score_avg"
      ) %>%
      dplyr::mutate(diff_score_avg = .data[["post_score_avg"]] - .data[["pre_score_avg"]]) %>%
      tidyr::pivot_longer(tidyselect::all_of(c("pre_score_avg","post_score_avg")),
                          names_to = c("timing", ".value"),
                          names_pattern = "([A-Za-z]+)_(.*)" # puts prefix of timing and then "score_avg" as the value
      )

  # If the user supplies a named vector for questions labels:
  if (!is.null(question_labels)) {
    names(question_labels) <- names(question_labels) %>%
      stringr::str_wrap(., width = 30) %>%
      gsub("\n", "<br>", .)
    arrow_df <- arrow_df %>%
      dplyr::mutate(question = forcats::fct_recode(.data$question, !!!question_labels)) %>%
      dplyr::ungroup()
  }

  # Set up a new question order if not supplied by the user by using the highest post score_avg:
  if (isFALSE(question_order)) {
    # Set up question as a factor and arrange by the top score_avg:
    question_order <- arrow_df %>%
      dplyr::arrange(dplyr::desc(.data$timing), dplyr::desc(.data$score_avg)) %>%
      dplyr::distinct(.data$question) %>%
      dplyr::mutate(question = as.character(.data$question)) %>%
      tibble::deframe()
    arrow_df <- arrow_df %>% dplyr::mutate(question = factor(.data$question, levels = question_order))
  } else {
    # If FALSE, use user supplied by order based on the set up the levels for question using- names(question_labels):
    arrow_df <- arrow_df %>% dplyr::mutate(question = factor(.data$question, levels = names(question_labels)))
  }

  # Get total n for each question, grouped by question and timing:
  totals_new_df <- {{ df }}  %>%
    dplyr::select(!"group") %>%
    tidyr::pivot_longer(tidyselect::everything(), names_to = "question", values_to = "response") %>%
    tidyr::separate(.data$question, into = c("timing", "question"), sep = "_") %>%
    dplyr::group_by(.data$question, .data$timing) %>%
    dplyr::mutate(timing = factor(.data$timing, levels = c("pre", "post"))) %>%
    dplyr::summarize(total = dplyr::n(), .groups = "keep") %>%
    dplyr::ungroup()

  # Return N_df that will be an overall n for all the items, only if all totals_new_df$total are equal:
  if (length(unique(totals_new_df$total)) == 1) {
    # Get overall n if it is the same for each item:
    N_df <- totals_new_df %>%
      dplyr::summarize(N = mean(.data$total)) %>%
      tibble::deframe()
  }

  # Calculate the nudge_x and hjust for the geom_text()
  # Pre
  pre_diff_score_avg <- arrow_df %>% dplyr::filter(.data[["timing"]] == "pre") %>% dplyr::select(.data[["diff_score_avg"]]) %>% tibble::deframe()
  nudge_x_pre <- dplyr::if_else(pre_diff_score_avg > 0, -0.075, 0.075)
  hjust_pre <- dplyr::if_else(pre_diff_score_avg > 0, 1, 0)
  # Post
  post_diff_score_avg <- arrow_df %>% dplyr::filter(.data[["timing"]] == "post") %>% dplyr::select(.data[["diff_score_avg"]]) %>% tibble::deframe()
  nudge_x_post <- dplyr::if_else(pre_diff_score_avg > 0, 0.075, -0.075)
  hjust_post <- dplyr::if_else(pre_diff_score_avg > 0, 0, 1)

  # If overall_n == TRUE:
  if (isTRUE(overall_n)) {
    arrow <- arrow_df %>%
      ggplot2::ggplot(ggplot2::aes(
        x = .data$score_avg, y = forcats::fct_rev(.data$group), color = forcats::fct_rev(.data$group),
        label = scales::number(.data$score_avg, accuracy = 0.01), group = .data$group
      )) +
      ggplot2::geom_path(
        lineend = "round", linejoin = "round", linewidth = 1,
        arrow = grid::arrow(type = "closed", length = ggplot2::unit(0.1, "inches"))
      ) +
      ggplot2::geom_text(
        data = dplyr::filter(arrow_df, .data$timing == "pre"), show.legend = FALSE,
        nudge_x = nudge_x_pre, hjust = hjust_pre, # calculated above.
        family = "Gill Sans MT", size = 3.5
      ) +
      ggplot2::geom_text(
        data = dplyr::filter(arrow_df, .data$timing == "post"), show.legend = FALSE,
        nudge_x = nudge_x_post, hjust = hjust_post, # calculated above.
        family = "Gill Sans MT", size = 3.5
      ) +
      ggplot2::facet_wrap(~question, ncol = 1, strip.position = "left") +
      ggplot2::scale_color_manual(values = group_colors, labels = function(group) stringr::str_to_title(group)) +
      ggplot2::scale_x_continuous(limits = c(1, 5), labels = scale_labels) +
      ggplot2::labs(tag = parse(text = paste0("(", expression(italic(n)), "==", N_df, ")")), color = NULL) +
      ggplot2::theme_void(base_family = "Gill Sans MT", base_size = 12) +
      ggplot2::theme(
        axis.text.x = ggtext::element_markdown(
          color = "#767171", size = 12, family = "Gill Sans MT",
          margin = ggplot2::margin(t = 5, r = 5, b = 5, l = 5, unit = "pt")
        ),
        strip.text.y.left = ggtext::element_markdown(
          angle = 0, hjust = 1, color = "black", size = 12, family = "Gill Sans MT",
          margin = ggplot2::margin(t = 5, r = 5, b = 5, l = 0, unit = "pt")
        ),
        plot.margin = ggplot2::margin(t = 5, r = 25, b = 5, l = 5, unit = "pt"),
        legend.position = "top"
      )
    # Otherwise, if overall_n == FALSE and, return an arrow chart with n for each question appended to the question label:
  } else {
    # Change the label of the variable "question" by adding n of each to the end of the character string:
    # Set up labels for question:
    labels_n_questions <- arrow_df %>%
      dplyr::mutate(
        labels = paste0(.data$question, " ", "(*n* = ", totals_new_df$total, ")"),
        labels = factor(.data$labels)
      ) %>%
      dplyr::arrange(.data$question) %>%
      dplyr::distinct(.data$labels) %>%
      tibble::deframe()

    # Set factor labels for question to labels = labels_n_questions:
    arrow_df <- arrow_df %>%
      dplyr::mutate(question = factor(.data$question, labels = labels_n_questions))

    # ggplot call for overall_n == FALSE
    arrow <- arrow_df %>%
      ggplot2::ggplot(ggplot2::aes(
        x = .data$score_avg, y = forcats::fct_rev(.data$group), color = forcats::fct_rev(.data$group),
        label = scales::number(.data$score_avg, accuracy = 0.01), group = .data$group
      )) +
      ggplot2::geom_path(
          lineend = "round", linejoin = "round", linewidth = 1,
          arrow = grid::arrow(type = "closed", length = ggplot2::unit(0.1, "inches"))
      ) +
      ggplot2::geom_text(
          data = dplyr::filter(arrow_df, .data$timing == "pre"), show.legend = FALSE,
          nudge_x = nudge_x_pre, hjust = hjust_pre, # calculated above.
          family = "Gill Sans MT", size = 3.5
      ) +
      ggplot2::geom_text(
          data = dplyr::filter(arrow_df, .data$timing == "post"), show.legend = FALSE,
          nudge_x = nudge_x_post, hjust = hjust_post, # calculated above.
          family = "Gill Sans MT", size = 3.5
      ) +
      ggplot2::facet_wrap(~question, ncol = 1, strip.position = "left") +
      ggplot2::scale_color_manual(values = group_colors, labels = function(group) stringr::str_to_title(group)) +
      ggplot2::scale_x_continuous(limits = c(1, 5), labels = scale_labels) +
      ggplot2::labs(tag = NULL, color = NULL) +
      ggplot2::theme_void(base_family = "Gill Sans MT", base_size = 12) +
      ggplot2::theme(
        axis.text.x = ggtext::element_markdown(
          color = "#767171", size = 12, family = "Gill Sans MT",
          margin = ggplot2::margin(t = 5, r = 5, b = 5, l = 5, unit = "pt")
        ),
        strip.text.y.left = ggtext::element_markdown(
          angle = 0, hjust = 1, color = "black", size = 12, family = "Gill Sans MT",
          margin = ggplot2::margin(t = 5, r = 5, b = 5, l = 0, unit = "pt")
        ),
        plot.margin = ggplot2::margin(t = 5, r = 25, b = 5, l = 5, unit = "pt"),
        legend.position = "top"
      )
  }

  return(arrow)
}


