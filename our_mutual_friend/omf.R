library(tidyverse)
library(tidytext)
library(textdata)
library(gutenbergr)
library(wordcloud2)
library(scales)

# Find and download Our Mutual Friend
gutenberg_metadata %>% 
  filter(title == "Our Mutual Friend") %>% 
  select(gutenberg_id, has_text)

omf <- gutenberg_download(883)

glimpse(omf)

# Divide into chapters and tokenize
omf <- omf %>%
  mutate(linenumber = row_number(),
         chapter = cumsum(str_detect(text, regex("^chapter [\\divxlc]",
                                                 ignore_case = TRUE)))) %>% 
  filter(chapter != 0)

omf <- omf %>%
  unnest_tokens(word, text) %>% 
  anti_join(stop_words)

# EDA

# top 10 words
omf %>% count(word, sort = TRUE) %>% 
  top_n(10, n) %>% 
  ggplot(aes(x = reorder(word, -n), y = n)) +
  geom_col()

# obligatory wordcloud
omf_wordfreq <- omf %>%
  count(word) %>% 
  mutate(total_words = sum(n),
         freq = n/total_words) %>% 
  arrange(desc(freq))

# set.seed(1212)
omf_wordfreq %>% slice(1:1000) %>% 
  wordcloud2(size = 0.5,
             shuffle = TRUE)

# better wordcloud with fancy font
library(showtext)

font_add(family = "RomanAntique",
         regular = "our_mutual_friend/fonts/RomanAntique.ttf")

showtext_auto()

# set.seed(1212)
omf_wordfreq %>% slice(1:100) %>% 
  wordcloud2(fontFamily = "RomanAntique",
             size = 0.5,
             shuffle = TRUE,
             color = "black")

# sentiment analysis with Bing et al. dictionary

omf_bing <- omf %>% 
  inner_join(get_sentiments("bing"))

omf_bing <- omf_bing %>% 
  group_by(chapter, sentiment) %>% 
  count() %>% 
  pivot_wider(names_from = sentiment, values_from = n) %>% 
  mutate(overall = positive - negative) %>% 
  ungroup()

omf_bing %>% 
  ggplot(aes(x = chapter, y = overall)) +
  geom_col() +
  labs(title = "Overall positive/negative sentiment by chapter",
       x = "Chapter",
       y = "Overall sentiment") +
  coord_cartesian(ylim = c(-175, 125)) +
  theme_minimal(base_size = 36) +
  theme(text = element_text(family = "RomanAntique"))

# ggsave("our_mutual_friend/omf_bing.png")


# sentiment analysis with NRC dictionary

get_sentiments("nrc")

omf_nrc <- omf %>% 
  inner_join(get_sentiments("nrc"))
omf_nrc

omf_nrc %>% count(sentiment, sort = TRUE) %>% 
  ggplot(aes(x = reorder(sentiment, n), y = n)) +
  geom_col() +
  scale_y_continuous(labels = comma_format()) +
  coord_flip() +
  labs(title = "Total sentiments according to NRC dictionary",
       x = "Sentiment",
       y = NULL) +
  theme_minimal(base_size = 26) +
  theme(text = element_text(family = "RomanAntique"))

# ggsave("our_mutual_friend/omf_nrc.png", scale = 0.8)
