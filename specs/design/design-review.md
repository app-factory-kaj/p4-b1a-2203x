# Design Review — Greeter Service

This document is an exhaustive critique of the current design, section by
section: the cell architecture, the domain model, the `greeter-api` component
definition, and its API contract. Each section ends with a one-line summary.

---

## 1. Architecture (`design.cell`)

The cell as drawn is about as minimal as a cell can be: one component,
`greeter-api`, declared as a `service`, with a single inbound edge from `west`
(the generic external caller) and no outbound edges at all. For a project
whose explicit purpose is to be a trivial reference implementation and a
Phase 4 checkpoint probe, this minimalism is largely appropriate — but
"appropriate for now" is not the same as "complete," and several gaps are
worth naming even if the team chooses, with eyes open, not to close them.

First, the cell carries no notion of environment or deployment topology
beyond the single component box. There is no distinction drawn between how a
caller inside the organization's network reaches `greeter-api` versus a
caller outside it, and the `exposure: intranet` setting living in the
component's `design.json` is invisible at the cell level — a reader of the
diagram alone cannot tell whether this service is internet-facing, VPC-only,
or something in between without opening the component file. Since the cell is
meant to be the first, fastest artifact a new reader or an architecture
reviewer consults, exposure should be legible from the diagram itself, not
only from a buried field. A caption or annotation on the component noting its
intranet-only exposure would remove an entire class of "is this safe to curl
from my laptop" questions.

Second, the cell omits any representation of cross-cutting platform
dependencies that every component on this platform implicitly rides on —
logging/observability sinks, the API gateway (if this service is ever to sit
behind one), and the Thunder identity provider, even though this particular
service explicitly opts out of authentication. An explicit "no-auth, by
design" annotation on the edge from `west` would make the deliberate absence
of a security boundary a visible design decision rather than something a
reviewer has to infer from the PRD's Product Decisions list. As written, a
future maintainer skimming only the cell could reasonably assume authn was
simply forgotten, not chosen.

Third, there is no operational or platform-resource dependency drawn even
though the service is fully stateless. This is correct — a stateless service
should show no platform-resource edges — but the cell would benefit from an
explicit note (even a text annotation, not a new edge) confirming "no
persistence by design," because the single most common follow-up question
reviewers ask about a "hello world" service is "where does it store
anything?" Making the absence explicit is cheap and forecloses an entire
round of back-and-forth.

Fourth, and most substantively: the cell draws exactly one edge, `west -> greeter-api`, and gives it no further annotation — no protocol, no expected
load, no SLA. For a reference/checkpoint service this is forgivable, but if
this project is genuinely meant to "double as a reference implementation for
other services" per the PRD's Solution section, the cell should model the
pattern other services are meant to copy with more fidelity: an edge
annotation naming the protocol (`HTTP/REST`), and perhaps a second,
illustrative inbound edge showing a named internal caller (e.g., a
`demo-client`) rather than only the anonymous `west` actor, so that teams
cloning this reference see a realistic multi-caller topology rather than a
degenerate single-edge graph.

Fifth, the title `Greeter Service` is accurate but does not signal the
project's secondary purpose as a Phase 4 checkpoint probe mentioned in the
PRD. A one-line comment at the top of the cell file (cell grammar permitting)
documenting that dual purpose would help a future reader understand why a
service this trivial has its own full spec bundle, design review, and
acceptance suite — without that context, the amount of process around such a
tiny service looks disproportionate.

Proposed improvements, concretely: (a) add an exposure annotation on the
`greeter-api` component node; (b) add a short text note near the `west` edge
recording the deliberate no-auth decision; (c) add a note confirming
statelessness; (d) consider widening the single anonymous edge into a named
illustrative caller if the reference-implementation goal is to be taken
seriously; (e) add a one-line comment documenting the Phase-4-probe purpose.
None of these require new components or new dependencies — they are
annotation-level improvements that cost nothing architecturally but
materially improve the cell's standalone legibility.

**Summary:** The cell is structurally correct but under-annotated — exposure, the no-auth decision, and statelessness are true but invisible, and should be made explicit rather than left to inference.

---

## 2. Domain Model (`domain-model.md`)

The domain model consists of a single entity, `GREETING`, with two fields,
`name` and `message`, explicitly framed as "a response shape, not a stored
record." This is an honest and useful framing — it would be a mistake to
dress up a stateless response payload as a persistent entity complete with an
ER diagram implying durability it does not have — but the honesty does not
fully compensate for the model's thinness, and there are several concrete
ways this document under-serves a reader trying to understand the service's
actual behavior from the model alone.

First, the model captures the shape of the output but says nothing about the
shape of the *input*. The service accepts an optional `name` query parameter
constrained to 100 characters, and that constraint is a first-class part of
the domain's behavior — it is the one validation rule in the entire service,
the one thing that can make a request fail — yet the domain model is silent
on it. A reader of `domain-model.md` alone would not learn that the `name`
field has a length bound, what happens when it is exceeded, or that this
bound is enforced at the boundary rather than deeper in the system. The
model should show the input constraint explicitly, even if briefly, since in
a service this small the input validation *is* the domain logic.

Second, the model does not represent the two distinct message-generation
rules as data: "Hello, World!" when no name is given, versus "Hello,
`<name>`!" when one is. These are two distinct derivations of the same field,
and a domain model that wants to earn its keep should show the derivation
rule, not just the resulting field name. As it stands, a reader has to cross
-reference the PRD's Product Decisions or the OpenAPI description string to
learn the exact two message forms; the domain model, which is supposed to be
the canonical place such business rules live, currently defers that
responsibility elsewhere.

Third, the model does not acknowledge the `Error` shape that the API
contract defines and that every real caller will eventually see (on a
400). An error response is as much a part of the domain as a success
response, and omitting it from the domain model means the model only tells
half the story of what a caller receives. Even a lightweight "ERROR {code,
message}" box, connected conceptually to `GREETING` via an "on invalid
input" relationship, would round out the model considerably and give
`domain-model.md` genuine claim to being the single source of truth for this
service's response shapes.

Fourth, there is a missed opportunity to use the domain model to document
*why* the model is this thin — i.e., to state explicitly that this is an
intentionally degenerate domain model because the service is intentionally
degenerate, as a teaching example. Right now the single sentence under the
diagram explains that `GREETING` is a response shape, which is good, but it
does not tie that choice back to the project's stated purpose as a reference
scaffold. A sentence doing so would help any team that copies this file as a
template understand which parts of the thinness are inherent to "hello
world" services and which parts (the missing input/error documentation
above) are gaps worth filling in even for a trivial service.

Fifth, mechanically, the Mermaid `erDiagram` block is a slightly unusual
choice for a model with no actual relationships — ER diagrams exist to show
cardinality between entities, and with a single entity and no relation line,
the diagram format is doing no real work beyond listing two fields in a box.
A plain fielded description, or a small `classDiagram`/schema-style block,
would communicate the same information with less implied (and unmet)
expectation that more entities and relationships are coming.

Proposed improvements: (a) add the `name` length constraint to the model; (b)
represent the two message-derivation rules explicitly, e.g. as a short rule
list beneath the diagram; (c) add an `ERROR` shape alongside `GREETING`; (d)
add a sentence tying the model's thinness to the project's reference-scaffold
purpose; (e) consider whether `erDiagram` is the right Mermaid diagram type
for a single, relationship-free entity.

**Summary:** The domain model correctly resists over-modeling a stateless service but currently omits the input constraint, the message-derivation rule, and the error shape, all of which belong in a model that claims to be canonical.

---

## 3. Component Design (`greeter-api/design.json`)

The component definition is clean, internally consistent, and traceable to
both stories — but a close reading surfaces several places where the
declared metadata either under-specifies the component or leaves decisions
implicit that a reviewer would reasonably expect to see stated.

First, `dependencies` is an empty array, and that is almost certainly
correct for a stateless, unauthenticated, storage-free service — but an
empty array is indistinguishable, at a glance, from a design that simply
never considered dependencies. Given that `api-management` and
`identity-access` are both live skills in this organization's library and
both are plausible candidates a reviewer would ask about ("does this sit
behind the gateway?", "does it need Thunder?"), the component would benefit
from a short `description` addendum or an adjacent note recording that these
were considered and deliberately excluded — "no gateway, no IDP, by design:
an intentionally open reference endpoint" — rather than leaving the empty
array to speak for itself.

Second, `exposure: intranet` is a meaningful security-relevant decision made
with no accompanying rationale anywhere in the component file. The PRD does
justify the no-auth stance ("fitting for a tiny utility/reference service
with no sensitive data") but does not separately justify *intranet* exposure
specifically — why not fully open internet-facing, given there is genuinely
nothing sensitive being protected? A reference service meant to be curled by
"another internal service or client application" per the PRD's Caller
definition arguably *should* be intranet-scoped for exactly that reason, but
the design.json does not surface that reasoning, and a future maintainer
changing exposure has no breadcrumb explaining the current choice.

Third, `version: 0.1.0` is a reasonable starting point but the design gives
no indication of this component's versioning policy going forward — whether
the OpenAPI `info.version` and the component `version` field are meant to be
kept in lock-step, whether a breaking change to the greeting message format
(say, adding a third field) would bump to `0.2.0` or `1.0.0`, and whether
this reference service is meant to ever reach a `1.0.0` "stable, safe to
depend on" milestone or stay perpetually pre-1.0 as a scaffold. For a service
explicitly intended to be copied as a template, an explicit versioning
convention would itself be part of the reference value delivered to copying
teams.

Fourth, `skillsPinned` lists `openapi-conventions` and `ballerina`, which
covers the contract and the language, but does not pin any testing or
verification skill, and the component file nowhere records what "done" looks
like for a build beyond passing the pinned skills' own build-verify steps.
Given the project's explicit secondary role as a Phase 4 checkpoint probe,
one would expect the component metadata to be unusually rigorous about
verification — if anything, this is the one component in the organization
where test coverage ought to be exemplary, precisely because other teams may
copy its conventions wholesale.

Fifth, the `description` field is a single dense paragraph doing a lot of
work — functional behavior, statelessness, and three negative assertions
("does not expose a UI, send notifications, or integrate with any
third-party service") all in one block. Splitting the negative-scope
assertions into their own sentence or field would make the file easier to
scan, and would mirror the PRD's own "Out of Scope" section structure rather
than re-deriving it in prose inside the component file.

Sixth, `appPath` and `entrypoint` are filled in ("greeter-api",
"deployment/service") but there is no accompanying note on the health-check
or readiness endpoint convention the organization expects a Ballerina
service to expose — for a checkpoint-probe project specifically meant to
validate repo conventions, this is exactly the kind of convention that
should be explicit rather than assumed to exist implicitly inside the
`ballerina` skill.

Proposed improvements: (a) annotate the empty `dependencies` array with a
rationale; (b) record the reasoning behind `intranet` exposure; (c) state an
explicit versioning policy; (d) consider pinning a verification-oriented
skill or at least documenting the expected test coverage; (e) split the
negative-scope assertions out of the dense description paragraph; (f)
document the expected health-check convention.

**Summary:** The component file is internally consistent and correctly scoped, but several consequential decisions — exposure rationale, versioning policy, and dependency rationale — are made without being written down anywhere a future maintainer can find them.

---

## 4. API Contract (`greeter-api/openapi.yaml`)

The contract is small, syntactically valid, and covers the two stories with
a single operation — but a single-operation contract is exactly the kind of
artifact where every remaining gap is maximally visible, and several are
worth calling out in detail.

First, the `/greeting` operation only defines `200` and `400` responses.
There is no `5xx` response documented anywhere, which for a reference
implementation is a missed teaching opportunity: a service meant to model
"the standard way this organization writes a contract" should show callers
what an unexpected failure looks like too, using the same `Error` schema
already defined, so that consuming teams see the full lifecycle of
responses, not just the happy path and the one validation error.

Second, the `400` response is triggered only by the 100-character `name`
bound, but the schema allows `name` to be an arbitrary string with no
pattern restriction beyond length — meaning, for instance, a `name` of empty
string (`""`) is accepted and would presumably render as "Hello, !", a
plainly malformed greeting. The contract does not document what happens with
an empty-but-present `name`, nor with a `name` containing control characters
or exclusively whitespace. For a contract whose entire validation surface is
this one field, these edge cases deserve explicit schema constraints (a
`minLength: 1` and perhaps a `pattern`) or, at minimum, explicit prose in the
parameter description stating the intended behavior.

Third, the `Greeting.name` property is marked `nullable: true` but the
response always includes a `message`, and the contract does not clarify
whether `name` is omitted entirely from the JSON body when absent versus
present-and-null — these are observably different wire formats for any
strict client-side deserializer, and the ambiguity is exactly the kind of
thing a reference contract should resolve explicitly rather than leave to
implementation accident.

Fourth, the `Error` schema's `code` field is typed as a generic `integer`
with no enumeration and no cross-reference to the one `400` case actually
defined. A contract this small could easily enumerate the exact, finite set
of error codes this service will ever emit, turning `code` into a closed set
rather than an open-ended integer — again, valuable specifically because
this is meant to be copied as a pattern by less experienced teams.

Fifth, there is no example value provided anywhere in the document — no
`example:` or `examples:` block on either the request parameter or the
response schemas. For an API this small, examples cost almost nothing to add
and dramatically improve onboarding for anyone integrating against it for
the first time, which given the explicit "reference implementation" goal of
this project, is precisely the audience this contract is written for.

Sixth, the contract declares `servers: - url: /` which is a reasonable
placeholder for local/relative resolution but documents nothing about the
actual deployed base path or host once this service is running behind
whatever gateway or intranet routing fronts it — a gap that mirrors the
missing exposure annotation noted in the cell review above.

Seventh, there is no rate-limiting, pagination, or versioning header
documented, which is entirely appropriate functionally, but the contract
could still usefully state, even in a comment, that these are deliberately
absent — again for the benefit of less experienced teams copying this file
wholesale, who might otherwise wonder whether their own contract is missing
something this one simply doesn't need.

Proposed improvements: (a) add a documented `5xx`/default error response
using the existing `Error` schema; (b) tighten the `name` parameter schema
with `minLength` and clarify empty/whitespace behavior; (c) resolve the
null-vs-omitted ambiguity on `Greeting.name`; (d) enumerate the finite set of
`Error.code` values this service can emit; (e) add example values to the
parameter and both response schemas; (f) document the real deployed server
URL once known; (g) add a short comment confirming the deliberate absence of
rate limiting, pagination, and versioning headers.

**Summary:** The contract is valid and covers the two stories, but leaves several edge cases (empty name, null-vs-omitted, undocumented 5xx) and onboarding aids (examples, enumerated error codes) unresolved for a document meant to double as a teaching reference.

---

## Overall

**One-line summary:** Every artifact in this design is functionally sound and internally consistent for a deliberately tiny service, but each one under-documents the *reasoning* behind its own deliberate minimalism — exposure, versioning, dependency absence, edge-case behavior — in ways that matter precisely because this project is meant to be copied as a reference.