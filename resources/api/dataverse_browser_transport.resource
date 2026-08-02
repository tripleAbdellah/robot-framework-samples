*** Settings ***
Documentation    Executes Dataverse Web API calls from *inside* the currently open,
...              already-authenticated page via fetch() — instead of a separate Python
...              HTTP client. A same-origin fetch() from the page runs through whatever
...              actually authenticates the app's own API calls: confirmed to be more
...              than cookies alone (a plain cookie replay from an external Python
...              client returned 401 against a real tenant), most likely a Service
...              Worker injecting a token (the app's own requests carried x-ms-sw-*
...              headers). Running inside the page sidesteps needing to know or
...              replicate that mechanism at all.
Library          Browser
Library          Collections
Library          String

*** Keywords ***
Dataverse Request In Browser
    [Documentation]    Makes one Dataverse Web API call from inside the page, retrying if
    ...                the browser was still mid-navigation. Dynamics 365's UCI app does
    ...                several client-side redirects right after login, which can destroy
    ...                the JS execution context mid-call — confirmed live via
    ...                "Execution context was destroyed, most likely because of a
    ...                navigation". Transient, not a real request error, so this retries
    ...                a few times rather than trying to wait for a "settled" page state
    ...                (Dynamics' persistent background polling makes networkidle-style
    ...                waits unreliable — same reasoning as avoiding Reload elsewhere).
    [Arguments]    ${method}    ${path}    ${body}=${None}
    ${result}=    Wait Until Keyword Succeeds    3x    2s
    ...    Execute Dataverse Fetch Once    ${method}    ${path}    ${body}
    RETURN    ${result}

Execute Dataverse Fetch Once
    [Documentation]    Single attempt at a Dataverse Web API call from inside the page.
    ...                See Dataverse Request In Browser for the retry wrapper around this.
    ...                Returns a dict: status, ok, json (parsed body, or ${None} if not
    ...                JSON), odataEntityId (the OData-EntityId response header, used to
    ...                read a newly-created record's id), and pageUrl (for diagnosing
    ...                wrong-origin failures). Fails if the response wasn't 2xx.
    [Arguments]    ${method}    ${path}    ${body}=${None}
    ${request}=    Create Dictionary    method=${method}    path=/api/data/v9.2/${path}    body=${body}
    ${result}=    Evaluate JavaScript    ${None}    async (req) => { const headers = {'Accept': 'application/json', 'OData-MaxVersion': '4.0', 'OData-Version': '4.0'}; if (req.body !== null) { headers['Content-Type'] = 'application/json'; } const response = await fetch(req.path, {method: req.method, headers: headers, body: req.body !== null ? JSON.stringify(req.body) : undefined}); let json = null; try { json = await response.json(); } catch (e) { json = null; } return {status: response.status, ok: response.ok, json: json, odataEntityId: response.headers.get('OData-EntityId'), pageUrl: window.location.href}; }    arg=${request}
    IF    not ${result}[ok]
        Fail    Dataverse API call ${method} ${path} failed with status ${result}[status] while the page was at '${result}[pageUrl]': ${result}[json]
    END
    RETURN    ${result}

Get Table Logical Name In Browser
    [Documentation]    Resolves a table's logical name from its display name (e.g.
    ...                'Klant' -> 'new_klant'). EntityDefinitions doesn't support
    ...                filtering on DisplayName server-side — confirmed against a real
    ...                tenant, where filtering on it returns 400 "Conditions based on
    ...                property DisplayName is not supported" — so this fetches every
    ...                table and matches display names client-side instead.
    [Arguments]    ${display_name}
    ${result}=    Dataverse Request In Browser    GET    EntityDefinitions?$select=LogicalName,DisplayName
    ${entities}=    Set Variable    ${result}[json][value]
    ${matches}=    Evaluate    [e for e in $entities if ((e.get('DisplayName') or {}).get('UserLocalizedLabel') or {}).get('Label') == $display_name]
    ${count}=    Get Length    ${matches}
    IF    ${count} == 0
        Fail    No table found with display name '${display_name}'
    END
    IF    ${count} > 1
        Fail    Multiple tables found with display name '${display_name}'
    END
    RETURN    ${matches}[0][LogicalName]

List Custom Tables In Browser
    [Documentation]    Fetches every table actually created by this org, for convention
    ...                checks. IsCustomEntity=true alone isn't enough — confirmed live
    ...                it also covers tables shipped by Microsoft's own optional modules
    ...                (msdyn_*, skill matching, workflow internals, etc.). The correct
    ...                signal is IsCustomEntity=true AND IsManaged=false: unmanaged means
    ...                created directly in this org, not installed via any managed
    ...                solution. Filtered client-side.
    ${fields}=    Set Variable    LogicalName,DisplayName,Description,IsCustomEntity,IsManaged,OwnershipType,IconVectorName,IconSmallName,IconMediumName,IconLargeName
    ${result}=    Dataverse Request In Browser    GET    EntityDefinitions?$select=${fields}
    ${entities}=    Set Variable    ${result}[json][value]
    ${custom_tables}=    Evaluate    [e for e in $entities if e.get('IsCustomEntity') and not e.get('IsManaged')]
    RETURN    ${custom_tables}

List Main Forms In Browser
    [Documentation]    Fetches every active Main Form (type=2) for a table. Unlike
    ...                EntityDefinitions, systemforms is a regular data entity —
    ...                confirmed live that compound $filter (objecttypecode + type +
    ...                formactivationstate) works normally here.
    [Arguments]    ${logical_name}
    ${path}=    Set Variable    systemforms?$select=name,type,formactivationstate,formxml&$filter=objecttypecode eq '${logical_name}' and type eq 2 and formactivationstate eq 1
    ${result}=    Dataverse Request In Browser    GET    ${path}
    RETURN    ${result}[json][value]

Get Table Metadata In Browser
    [Documentation]    Fetches table (entity) metadata: attributes, types, display names.
    [Arguments]    ${logical_name}
    ${path}=    Set Variable    EntityDefinitions(LogicalName='${logical_name}')?$expand=Attributes($select=LogicalName,AttributeType,DisplayName)
    ${result}=    Dataverse Request In Browser    GET    ${path}
    RETURN    ${result}[json]

Create Record In Browser
    [Documentation]    Creates a record in the given entity set. Returns its id.
    [Arguments]    ${entity_set}    ${data}
    ${result}=    Dataverse Request In Browser    POST    ${entity_set}    ${data}
    ${record_id}=    Extract Guid From OData Entity Id    ${result}[odataEntityId]
    RETURN    ${record_id}

Get Record In Browser
    [Documentation]    Fetches a record by id, optionally limiting fields via select.
    [Arguments]    ${entity_set}    ${record_id}    ${select}=${None}
    IF    $select is not None
        ${path}=    Set Variable    ${entity_set}(${record_id})?$select=${select}
    ELSE
        ${path}=    Set Variable    ${entity_set}(${record_id})
    END
    ${result}=    Dataverse Request In Browser    GET    ${path}
    RETURN    ${result}[json]

Delete Record In Browser
    [Documentation]    Deletes a record by id.
    [Arguments]    ${entity_set}    ${record_id}
    Dataverse Request In Browser    DELETE    ${entity_set}(${record_id})

Extract Guid From OData Entity Id
    [Documentation]    Pulls the record GUID out of an OData-EntityId response header,
    ...                e.g. ".../persons(11111111-2222-3333-4444-555555555555)".
    [Arguments]    ${odata_entity_id}
    ${matches}=    Get Regexp Matches    ${odata_entity_id}    \\(([0-9a-fA-F-]{36})\\)    1
    RETURN    ${matches}[0]
