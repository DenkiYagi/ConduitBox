package conduitbox.types;

typedef Location = {
    path: String,
    ?query: Map<String, String>,
    ?hash: String
}