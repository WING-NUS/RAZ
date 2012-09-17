These are files used to run the web service for RAZ at NUS.  You are
welcomed to use them.  However, the authoritative version of these
files will be located on ~wing.nus/services/raz/bin/, not in this
distribution.  This is a copy of the executables in that directory.

-Min (16 Sep 2012)

----------------------------------------------------------------------
Relevant Emails:

1) 8 February 2010 from Emma:

I've also put up a web service for ParsCit++, it is under /home/forecite/services/logicalStruct/

The syntax is : ruby LogicalStructureClient.rb paper_id type

Types include the logical structure ("title","author","note","email","sectionHeader",                    "bodyText","page","definition","equation","listItem",                   "subsectionHeader","figureCaption","figure","tableCaption","reference",          "affiliation","address","keyword","category","phone",
"footnote","algorithm","program","table","none",                     "subsubsectionHeader","construct","theorem","proof","copyright", "web","proposition")

and  the generic section headers ("abstract","keywords","introduction","background","method",                       "evaluation","relatedWorks","discussions","conclusions", "acknowledgments","references")

and "fulltext"(paper's fulltext) , "header" (paper's header)

Please tell me if there's any changes that need to be done for the RAZ display as well as the new web service.

Thanks,
Emma

2) 22 April 2010 from Emma:

Hi Min,
Below is the email regarding the web service. I copied it here for a quick reference.

It is in /home/forecite/services/logicalStruct/
The logical structure is extracted using the old SectLabel, so it's not really accurate yet.

The syntax is now a little bit different : ruby LogicalStructureClient.rb [md5] [label]

Labels include the logical structure
  ("title","author","note","mail","sectionHeader",
   "bodyText","page","definition","equation","listItem",
   "subsectionHeader","figureCaption","figure","tableCaption","reference",
   "affiliation","address","keyword","category","phone",
   "footnote","algorithm","program","table","none",
   "subsubsectionHeader","construct","theorem","proof","copyright",
   "web","proposition")

 and  the generic section headers

  ("abstract","categories_and_subject_descriptors","general_terms","keywords",
   "introduction", "background", "method", "evaluation", "related_work", "discussions",
   "conclusions", "acknowledgments","references")

Emma
