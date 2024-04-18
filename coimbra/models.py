from dataclasses import dataclass


@dataclass(kw_only=True)
class _Base:
    id: int
    name: str
    description: str
    status: str
    progress: str
    priority: str
    duration: str
    notes: str


@dataclass(kw_only=True)
class Topic(_Base):
    resources: list[Resource]
    subtopics: list[Topic]


@dataclass(kw_only=True)
class Resource(_Base):
    url: str


@dataclass(kw_only=True)
class MetaResource(Resource):
    type: str = "meta_resource"


@dataclass(kw_only=True)
class Book(Resource):
    type: str = "book"
    authors: list[str]
    isbn: str
    ...  # etc...


@dataclass(kw_only=True)
class YoutubeVideo(Resource):
    type: str = "youtube_video"


# etc...
