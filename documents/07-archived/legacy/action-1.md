đọc documents\99-archived\linkedin-ai-agent-strategy.md và đánh giá tính khả thi về dự án này

hãy tạo báo cáo tương tự về ai agent để đăng bài facebook, đối với bài đăng facebook, tôi đang hướng đến 2 content chính:
1. lập trình, ai, cloud
2. học tiếng trung

ý tôi là mỗi content 1 page chứ không gộp chung

đưa hết tài liệu vào folder riêng theo best pratice trong document kể cả linkedin-ai-agent-strategy
file documents\facebook-ai-agent-strategy.md còn cần thiết không?
tạo báo cáo về tech stack sử dụng

hãy quét 1 lượt các folder mới được tôi thêm vào, hãy đánh giá các file nào hữu dụng cho dự án này thì thực hiện commit lại theo skill commit
đề xuất action tiếp theo (ví dụ bổ sung các skill mới phù hợp cho projetc này)

trong các folder tôi mới thêm, tôi thấy 1 số skill + rule, config là hữu dụng cho project, ví dụ, cách commit cũng có

config sai rồi, hãy thêm vào skill, config name: VictorAurelius, email:vankiet14491@gmail.com
commit
hãy tạo plan để:
1. đánh giá các skill, file được move từ kiteclass sang
2. loại bỏ những file thực sự sẽ không dùng đến trong tương lai
3. học tập và bổ sung skill, hoành thiện quy trình cho dự án này
4. đặt lên tên cho dự án

đọc tài liệu để hiểu về dự án

tôi đã mở docker desktop, giúp tôi chạy task 1.5

lỗi gì trong quá trình setup thì sửa script, rule của dự án là không chạy thẳng lệnh docker, phải qua script, lưu vào memory

nó điều hướng tôi đến http://localhost:5678/setup luôn

tất cả những bước này không tạo thành script tự động được sao?

Click Credentials (icon chìa khóa bên trái) => không tìm thấy ở http://localhost:5678/home/workflows

làm sao để tìm bot father?

rule là gì?

Base URL của tele creden là gì?

commit và tuân thủ quy trình fix của superpowers

tôi chưa hài lòng với quy trình fix này, mỗi lần fix hoặc feature phải tạo branch, fix, tạo pull request, cập nhật lại skill

fix theo đúng chuẩn của superpowers

tài liệu mô tả về 4 PR lần này

check 2 bài đăng này:
https://www.linkedin.com/posts/alexxubyte_systemdesign-coding-interviewtips-share-7439698363677290496-Ozmp?utm_source=share&utm_medium=member_desktop&rcm=ACoAAFPi1C4B8CnR5jCDqYbZwOBy2qIBEvQEIiY
https://www.linkedin.com/posts/sivasankar-natarajan_agenticai-aiprotocols-genai-share-7439343782329876480-Tw1y?utm_source=share&utm_medium=member_desktop&rcm=ACoAAFPi1C4B8CnR5jCDqYbZwOBy2qIBEvQEIiY

hình ảnh họ dùng là định dạng gì, sao lại có chuyển động hay vậy, hệ thống có thể tạo ra được không?

có vẻ nó là dạng gif

tạo 2 PR PDE và Image luôn theo chuẩn superpower

bạn nghĩ sao về việc đưa lên production chạy bằng free-tier sẽ có thể sử dùng ollama nhiều tham số hơn:
✅ Thông tin CHÍNH XÁC
ARM Compute: 4 CPU + 24GB RAM
Oracle cung cấp ARM-based VM (Ampere A FreeTiers1) với tối đa 4 OCPU và 24GB RAM miễn phí vĩnh viễn, kèm 200GB block storage.
x86 Compute: 2 VMs x (1/8 CPU + 1GB)
Hai AMD-based Compute VM, mỗi cái có 1/8 OCPU và 1 GB memory, phù hợp cho app nhỏ hoặc dev environment. Topuser
Load Balancer: 1 LB (10 Mbps)
Tất cả tenancy được tạo từ 15/12/2020 trở đi sẽ có 1 Always Free Flexible Load Balancer với bandwidth tối thiểu và tối đa là 10 Mbps. Oracle
Outbound: 10 TB/tháng và Vĩnh viễn
Tính đến 2026, Oracle Cloud Always Free Tier vẫn hoạt động bình thường với các tài nguyên chủ chốt không thay đổi, bao gồm Ampere A1 (4 OCPU, 24GB RAM), 200GB block storage. Grokipedia
Idle reclamation: CPU <20%
Oracle xác định VM là idle nếu trong 7 ngày, CPU utilization ở percentile thứ 95 dưới 20% — đây là chính sách chính thức từ Oracle docs. Oracle ✅ Document ghi đúng.

đọc .claude\starter-kit\README.md để apply kit vào dự án

không cần apply các vấn đề khác mà kit đề cập sao?

cần refactor cấu trúc folders hiện tại theo tiêu chuẩn của kit không?

tạo PR đúng chuẩn để refactor FULL

ngoài ra tôi định đổi tên dự án thành AI AGENT PERSONAL phục vụ các công việc của tôi thay vì focus vào mảng social, vậy hiện tại đang có 2 mảng trong repo: novel-translation và social, cùng cần refactor rõ ràng cái nào là common, cái nào là riêng về domain đó
lưu cũng cũng phải apply thay đổi đường dẫn trong thông tin file