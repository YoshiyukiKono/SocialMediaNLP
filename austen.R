install.packages(c("janeaustenr"))
library(janeaustenr)

library(dplyr)
library(sparklyr)

config <- spark_config()

config$sparklyr.driver.memory <- "16G"
config$sparklyr.executor.memory <- "16G"
config$spark.yarn.executor.memoryOverhead <- "8g"

#### Configuration for sparklyr


#config[["spark.r.command"]] <- "./r_env.zip/r_env/bin/Rscript"

#config[["spark.r.command"]] <- "./r_env.zip/r_env/bin/R"

config[["spark.yarn.dist.archives"]] <- "r_env.zip"
config$sparklyr.apply.env.R_HOME <- "./r_env.zip/r_env/lib/R"
config$sparklyr.apply.env.RHOME <- "./r_env.zip/r_env"
config$sparklyr.apply.env.R_SHARE_DIR <- "./r_env.zip/r_env/lib/R/share"
config$sparklyr.apply.env.R_INCLUDE_DIR <- "./r_env.zip/r_env/lib/R/include"
config$sparklyr.apply.env.LD_LIBRARY_PATH <- "/opt/cloudera/parcels/Anaconda/lib"
config$sparklyr.apply.env.PYTHONPATH <- "./r_env.zip/r_env/lib/python2.7/site-packages/"
# Spacyr checkes if Python exits using "which/where" command, so PATH is needed even when using the full path.
config$sparklyr.apply.env.PATH <- "/opt/cloudera/parcels/Anaconda/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/centos/.local/bin:/home/centos/bin"





#### Connect spark
#sc <- spark_connect(master = "yarn-client", config = config)

sc <- spark_connect(master = "yarn-client")


#### Concatinate texts per document
austen     <- austen_books()
text_by_book <- austen_books() %>%
  group_by(book) %>%
  mutate(text_by_book = paste0(text, collapse = " ")) %>% 
  select(book, text_by_book) %>%
  distinct() %>%
  rename(text = text_by_book)
text_by_book$doc_id <- seq.int(nrow(text_by_book))

#### Create Spark Data Frame
austen_tbl <- copy_to(sc, text_by_book, overwrite = TRUE)

#### Extract named entities with `spark_apply()`
entities <- austen_tbl %>%
  select(text) %>%
  spark_apply(
    function(e) 
    {
      lapply(e, function(k) {
        
          library("spacyr")
          #spacy_install()
        
          spacyr::spacy_initialize()
          #spacyr::spacy_initialize(python_executable="/opt/cloudera/parcels/Anaconda/bin/python")
          parsedtxt <- spacyr::spacy_parse(as.character(k), lemma = FALSE)
          spacyr::entity_extract(parsedtxt)
        }
      )
    },
    names = c("doc_id", "sentence_id", "entity", "entity_type"),
    packages = FALSE)

#### Show results
entities %>% head(10) %>% collect()

grouped_entities <- entities %>% 
  group_by(entity_type) %>% 
  count() %>% 
  arrange(desc(n)) %>%
  collect()
  

grouped_entities

#### Plot the graph

library(ggplot2)

p <- entities %>%
  collect() %>% 
  ggplot(aes(x=factor(entity_type)))
p <- p + scale_y_log10()
p + geom_bar()

#### Show Top 10 persons for each document

persons <- entities %>% 
  filter(entity_type == "PERSON") %>%
  group_by(doc_id, entity) %>%
  select(doc_id, entity) %>%
  count() %>%
  arrange(doc_id, desc(n))

persons %>% 
  filter(doc_id == "text1") %>%
  head(10) %>%
  collect()

persons %>% 
  filter(doc_id == "text2") %>%
  head(10) %>%
  collect()



spark_disconnect(sc)
connection_is_open(sc)