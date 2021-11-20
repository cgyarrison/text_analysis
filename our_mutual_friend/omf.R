library(tidyverse)
library(tidytext)
library(textdata)
library(gutenbergr)

gutenberg_metadata %>% 
  filter(title == "Our Mutual Friend") %>% 
  select(gutenberg_id, has_text)

omf <- gutenberg_download(883)

glimpse(omf)

omf <- omf %>%
  mutate(linenumber = row_number(),
         chapter = cumsum(str_detect(text, regex("^chapter [\\divxlc]",
                                                 ignore_case = TRUE)))) %>% 
  filter(chapter != 0)

omf <- omf %>%
  unnest_tokens(word, text) %>% 
  anti_join(stop_words)

omf %>% count(word, sort = TRUE) %>% 
  top_n(10, n) %>% 
  ggplot(aes(x = reorder(word, -n), y = n)) +
  geom_col()

omf_bing <- omf %>% 
  inner_join(get_sentiments("bing"))

omf_bing %>% group_by(chapter, sentiment) %>% 
  count() %>% 
  pivot_wider(names_from = sentiment, values_from = n) %>% 
  mutate(overall = positive - negative)

omf_bing %>% group_by(chapter, sentiment) %>% 
  count() %>% 
  pivot_wider(names_from = sentiment, values_from = n) %>% 
  mutate(overall = positive - negative) %>% 
  ggplot(aes(x = chapter, y = overall)) +
  geom_col()

get_sentiments("nrc")

omf_nrc <- omf %>% 
  inner_join(get_sentiments("nrc"))
omf_nrc

omf_nrc %>% count(sentiment, sort = TRUE) %>% 
  ggplot(aes(x = reorder(sentiment, -n), y = n)) +
  geom_col()

omf_nrc %>% ggplot(aes(x = chapter, fill = sentiment)) +
  geom_bar(show.legend = FALSE) +
  facet_wrap(~ sentiment)

omf_nrc_meansent <- omf_nrc %>% 
  group_by(sentiment, chapter) %>% 
  summarize(count = n()) %>% 
  group_by(sentiment) %>% 
  mutate(mean_sentiment = mean(count)) %>% 
  summarize(mean_sentiment = mean(mean_sentiment))

omf_nrc %>% ggplot(aes(x = chapter, fill = sentiment)) +
  geom_hline(data = omf_nrc_meansent,
             aes(yintercept = mean_sentiment)) +
  geom_bar(show.legend = FALSE) +
  facet_wrap(~ sentiment)

omf_nrc %>% ggplot(aes(x = chapter)) +
  geom_density(aes(fill = sentiment), alpha = 0.5)

omf_nrc %>% ggplot(aes(x = chapter)) +
  geom_density(aes(fill = sentiment), alpha = 0.5,
               position = "fill")

# normalize for % of sentiment per chapter/overall

omf_nrc %>% group_by(chapter) %>% 
  summarize(words_in_chapter = n()) %>% 
  group_by(chapter, sentiment) %>% 
  summarize(sentiment_in_chapter = n(),
         sentiment_per_chapter = sentiment_in_chapter/words_in_chapter)

omf_nrc %>% group_by(chapter, sentiment) %>% 
  summarize(sentiment_in_chapter = n()) %>% 
  group_by(chapter) %>% 
  mutate(words_in_chapter = sum(sentiment_in_chapter),
         sentiment_per_chapter = sentiment_in_chapter/words_in_chapter) %>% 
  ggplot(aes(x = chapter, y = sentiment_per_chapter)) +
  geom_col() +
  facet_wrap(~ sentiment)
