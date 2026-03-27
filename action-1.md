chưa merge được:
1. chưa download jar cho local
2. tạo plan để render các diagrams trực quan cho dự án hiện tại

merge và tạo PR riêng theo chuẩn của kit

cấu hình git để ko nhận changing cho jar => cập nhật kit

skill có đề cập đến phải dùng jar (không dùng công cụ khác để render) không? nếu không thì cập nhật kit

skill có đề cập phải check ảnh render xem script có đúng hay lỗi không? nếu lỗi thì đương nhiên fix, nếu chưa thì cập nhật lại kit

nhớ đẩy version theo rule của kit

fix luôn ở nhánh này

cập nhật skill về việc thiếu này, mk wsl là "vkiet432", không vi phạm security vì tôi chỉ dùng wsl để phát triển

bài luận 1 chút về starter-kit đi, đây là 1 personal claude skills kit của tôi, việc nó chỉ là 1 folder khiến tôi bất tiện khi update và apply ở các dự án, best practice nên cả thiện là gì?
là 1 sub repo hay plugin hay phương án khác

tạo PR mới để thực hiện

thử cài plugin cho dự án này, nếu cập nhật kit thì sao?

làm sao để tôi hướng dẫn dự án cài đặt kit và lựa chọn customize tốt

ý tôi là dự án trắng mới hoặc dự án cũ đã có kit thì chỉ lệnh cài đặt/ cập nhật kit như thế nào, cho tôi prompt ngắn gọn hoặc file

ý tôi là nói với claude hãy làm gì ấy

tìm hiểu tổng quan về dự án này

tôi muốn xây dựng module tiếp theo:
module dịch sách tiếng anh
module này không phải 1 workflow tự động mà là xây dựng 1 quy trình dịch sách tiếng anh chuẩn chỉ, hỗ trợ:
1. các skills dịch thông minh, phân được mức độ văn phong, ...
2. quy trình dịch để người dùng review cục bộ và toàn phần dễ dàng, model dịch luôn là Claude max plan - chính là bạn
3. hệ thống skills hoặc memory để lưu lại các điều chỉnh đến từ user
4. scripts render docx, tham chiếu file output dịch, có thể là md để tạo hệ thông scripts python để render ra output cuối cùng là file word

hãy đánh giá xem modules này có khả thi không? có repo nào tương tự trên github chưa? hay có bộ skills về dịch sách nào tương tự chưa?

có 2 vấn đề:
1. tôi có 2 prompt của lần dịch trước, có giá trị tham khảo thôi, cũng chưa đầy đủ:
documents\07-archived\legacy\DICH_PROMPT_1.txt
documents\07-archived\legacy\DICH_PROMPT_2.txt
2. script render docx nên là 1 hệ thông scripts khoa học vì file docx cần render sẽ có khá nhiều trang, đúng không?

start

file PDF hoặc docx đầu vào có format riêng, cần trả output docx theo format đó, phục vụ để biên tập có thể mapping dễ dàng

chỉ B thôi

cài gh CLI rồi, nhưng chưa nhận đường dẫn thôi

sửa lại .claude\settings.local.json, cấp full quyền cho claude theo skill

có nhiều file chưa được commit