package conduitbox;

typedef Location = {
    path: String,
    ?query: Map<String, String>,
    ?hash: String
}